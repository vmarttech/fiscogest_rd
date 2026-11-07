import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:fiscogest_rd/features/e_cf/domain/ports/ecfe_signer.dart';
import 'package:xml/xml.dart';
import 'package:xml_crypto/xml_crypto.dart';
import 'package:fiscogest_rd/features/e_cf/data/xml/pkcs12_movil.dart';

/// Firma XML e-CF con certificado PKCS#12 (.p12/.pfx).
///
/// Estrategia (escritorio Linux/Windows con OpenSSL):
/// 1. Extrae clave privada y certificado del .p12 con openssl.
/// 2. Calcula digest SHA-256 del documento (C14N simplificado / bytes UTF-8
///    del XML sin Signature), estilo enveloped.
/// 3. Firma el SignedInfo con RSA-SHA256 vía openssl dgst -sign.
/// 4. Inserta el bloque Signature (XMLDSig enveloped).
///
/// Alinear al 100% con el PDF "Firmado de e-CF" de la DGII (C14N exacto)
/// durante certificación; este implementador cubre el flujo productivo base.
class _EcfeProcessRunner {
  static const Duration timeout = Duration(seconds: 30);
  static const Duration cleanupTimeout = Duration(seconds: 2);

  static Future<ProcessResult> run(
    String executable,
    List<String> arguments,
  ) async {
    final process = await Process.start(
      executable,
      arguments,
      runInShell: false,
    );

    final stdoutFuture = process.stdout.transform(utf8.decoder).join();
    final stderrFuture = process.stderr.transform(utf8.decoder).join();

    try {
      final exitCode = await process.exitCode.timeout(timeout);
      final stdout = await stdoutFuture.timeout(timeout);
      final stderr = await stderrFuture.timeout(timeout);
      return ProcessResult(process.pid, exitCode, stdout, stderr);
    } on TimeoutException {
      process.kill();
      try {
        await process.exitCode.timeout(cleanupTimeout);
      } catch (_) {}
      try {
        await stdoutFuture.timeout(cleanupTimeout);
      } catch (_) {}
      try {
        await stderrFuture.timeout(cleanupTimeout);
      } catch (_) {}
      rethrow;
    }
  }
}

class EcfeSignerImpl implements EcfeSigner {
  EcfeSignerImpl({
    required this.rutaCertificado,
    required this.claveCertificado,
  });

  final String rutaCertificado;
  final String claveCertificado;

  @override
  Future<String> firmar(String xmlSinFirma) async {
    final certPath = rutaCertificado.trim();
    if (certPath.isEmpty) {
      throw StateError('Ruta de certificado no configurada');
    }
    final certFile = File(certPath);
    if (!await certFile.exists()) {
      throw StateError('Certificado no encontrado: $certPath');
    }
    if (claveCertificado.isEmpty) {
      throw StateError('Clave del certificado vacía');
    }

    final openssl = await _whichOpenssl();
    if (openssl == null) {
      if (Platform.isAndroid || Platform.isIOS) {
        return _firmarEnMovil(xmlSinFirma);
      }
      throw StateError(
        'OpenSSL no esta en el PATH. Instalalo para firmar e-CF en esta computadora.',
      );
    }

    final tmp = await Directory.systemTemp.createTemp('ecfe_sign_');
    try {
      // En sistemas POSIX, solo el propietario debe acceder a la clave temporal.
      // Si no se puede proteger el directorio, no continuar con material secreto.
      if (!Platform.isWindows) {
        final permisos = await _EcfeProcessRunner.run('chmod', [
          '700',
          tmp.path,
        ]);
        if (permisos.exitCode != 0) {
          throw StateError(
            'No se pudieron proteger los archivos temporales de la firma.',
          );
        }
      }

      final keyPem = File('${tmp.path}/key.pem');
      final certPem = File('${tmp.path}/cert.pem');
      final p12PassFile = File('${tmp.path}/p12.pass');
      await p12PassFile.writeAsString(claveCertificado, flush: true);

      // Extraer clave privada
      final rKey = await _EcfeProcessRunner.run(openssl, [
        'pkcs12',
        '-in',
        certPath,
        '-nocerts',
        '-nodes',
        '-passin',
        'file:${p12PassFile.path}',
        '-out',
        keyPem.path,
      ]);
      if (rKey.exitCode != 0) {
        throw StateError(
          'No se pudo leer la clave privada del certificado .p12. Verifica la contraseña y el archivo.',
        );
      }

      // Extraer certificado X509
      final rCert = await _EcfeProcessRunner.run(openssl, [
        'pkcs12',
        '-in',
        certPath,
        '-clcerts',
        '-nokeys',
        '-passin',
        'file:${p12PassFile.path}',
        '-out',
        certPem.path,
      ]);
      if (rCert.exitCode != 0) {
        throw StateError(
          'No se pudo leer el certificado público del archivo .p12. Verifica el archivo.',
        );
      }

      final x509B64 = _extractCertBase64(await certPem.readAsString());
      if (x509B64.isEmpty) {
        throw StateError('Certificado X509 vacío en el .p12');
      }

      // Documento a firmar: quitar cualquier Signature previa
      final xmlLimpio = _conFechaHoraFirma(
        _stripSignature(xmlSinFirma.trim()),
        DateTime.now(),
      );
      final xmlParaFirma = _canon(xmlLimpio);
      final digestValue = base64.encode(
        sha256.convert(utf8.encode(xmlParaFirma)).bytes,
      );

      final signedInfo =
          '<SignedInfo xmlns="http://www.w3.org/2000/09/xmldsig#">'
          '<CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>'
          '<SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>'
          '<Reference URI="">'
          '<Transforms>'
          '<Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>'
          '</Transforms>'
          '<DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>'
          '<DigestValue>$digestValue</DigestValue>'
          '</Reference>'
          '</SignedInfo>';

      final siFile = File('${tmp.path}/signedinfo.xml');
      await siFile.writeAsString(_canon(signedInfo), flush: true);
      final sigOut = File('${tmp.path}/sig.bin');

      // RSA-SHA256 sobre SignedInfo
      final rSign = await _EcfeProcessRunner.run(openssl, [
        'dgst',
        '-sha256',
        '-sign',
        keyPem.path,
        '-out',
        sigOut.path,
        siFile.path,
      ]);
      if (rSign.exitCode != 0) {
        throw StateError(
          'OpenSSL no pudo firmar SignedInfo. Verifica el certificado y los datos.',
        );
      }
      final signatureValue = base64.encode(await sigOut.readAsBytes());

      final signatureXml =
          '<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">'
          '${_canon(signedInfo)}'
          '<SignatureValue>$signatureValue</SignatureValue>'
          '<KeyInfo><X509Data><X509Certificate>$x509B64</X509Certificate></X509Data></KeyInfo>'
          '</Signature>';

      return '<?xml version="1.0" encoding="UTF-8"?>${_insertSignature(xmlParaFirma, signatureXml)}';
    } on TimeoutException {
      throw StateError(
        'La operación de firma excedió el límite de 30 segundos. '
        'Verifica OpenSSL y vuelve a intentarlo.',
      );
    } finally {
      try {
        await tmp.delete(recursive: true);
      } catch (_) {}
    }
  }

  Future<String> _firmarEnMovil(String xmlSinFirma) async {
    final xmlLimpio = _conFechaHoraFirma(
      _stripSignature(xmlSinFirma.trim()),
      DateTime.now(),
    );
    final xmlParaFirma = _canon(xmlLimpio);
    final digestValue = base64.encode(
      sha256.convert(utf8.encode(xmlParaFirma)).bytes,
    );
    final signedInfo =
        '<SignedInfo xmlns="http://www.w3.org/2000/09/xmldsig#">'
        '<CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>'
        '<SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>'
        '<Reference URI="">'
        '<Transforms>'
        '<Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>'
        '</Transforms>'
        '<DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>'
        '<DigestValue>$digestValue</DigestValue>'
        '</Reference>'
        '</SignedInfo>';
    final firmado = await Pkcs12Movil.firmar(
      ruta: rutaCertificado,
      clave: claveCertificado,
      datos: Uint8List.fromList(utf8.encode(_canon(signedInfo))),
    );
    final signatureValue = firmado.firma;
    final x509B64 = firmado.certificado;
    final signatureXml =
        '<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">'
        '${_canon(signedInfo)}'
        '<SignatureValue>$signatureValue</SignatureValue>'
        '<KeyInfo><X509Data><X509Certificate>$x509B64</X509Certificate></X509Data></KeyInfo>'
        '</Signature>';
    return '<?xml version="1.0" encoding="UTF-8"?>'
        '${_insertSignature(xmlParaFirma, signatureXml)}';
  }

  static Future<String?> _whichOpenssl() async {
    for (final command in <List<String>>[
      ['which', 'openssl'],
      ['where', 'openssl'],
    ]) {
      try {
        final result = await _EcfeProcessRunner.run(
          command.first,
          command.skip(1).toList(),
        );
        if (result.exitCode == 0) {
          final String output = result.stdout.toString().trim();
          if (output.isNotEmpty) {
            return output.split('\n').first.trim();
          }
        }
      } on TimeoutException {
        // La detección no debe quedar bloqueada indefinidamente.
      } on ProcessException {
        // El comando puede no existir en este sistema operativo.
      }
    }
    return null;
  }

  static String _extractCertBase64(String pem) {
    final match = RegExp(
      r'-----BEGIN CERTIFICATE-----([\s\S]*?)-----END CERTIFICATE-----',
    ).firstMatch(pem);

    if (match == null) {
      throw const FormatException(
        'No se encontró el certificado X509 en formato PEM',
      );
    }

    final base64Cert = match.group(1)!.replaceAll(RegExp(r'\s+'), '');

    if (base64Cert.isEmpty ||
        !RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(base64Cert)) {
      throw const FormatException(
        'El certificado X509 contiene Base64 inválido',
      );
    }

    return base64Cert;
  }

  static const String _xmlDsigNamespace = 'http://www.w3.org/2000/09/xmldsig#';

  static String _stripSignature(String xml) {
    final doc = XmlDocument.parse(xml);

    void limpiar(XmlElement padre) {
      for (final nodo in padre.children.toList()) {
        if (nodo is! XmlElement) continue;

        final esFirmaXmlDsig =
            nodo.name.local == 'Signature' &&
            nodo.namespaceUri == _xmlDsigNamespace;

        if (esFirmaXmlDsig) {
          nodo.remove();
        } else {
          limpiar(nodo);
        }
      }
    }

    limpiar(doc.rootElement);

    return doc.toXmlString(pretty: false);
  }

  static String _conFechaHoraFirma(String xml, DateTime firma) {
    String dos(int n) => n.toString().padLeft(2, '0');

    final texto =
        '${dos(firma.day)}-${dos(firma.month)}-${firma.year} '
        '${dos(firma.hour)}:${dos(firma.minute)}:${dos(firma.second)}';

    final doc = XmlDocument.parse(xml);

    void eliminarFecha(XmlElement padre) {
      for (final nodo in padre.children.toList()) {
        if (nodo is! XmlElement) continue;

        if (nodo.name.local == 'FechaHoraFirma' && nodo.namespaceUri == null) {
          nodo.remove();
        } else {
          eliminarFecha(nodo);
        }
      }
    }

    eliminarFecha(doc.rootElement);

    doc.rootElement.children.add(
      XmlElement(XmlName('FechaHoraFirma'), [], [XmlText(texto)]),
    );

    return doc.toXmlString(pretty: false);
  }

  /// Serializa un documento XML de forma determinista para cálculo de digest
  /// y firma (XMLDSig enveloped).
  ///
  /// Se declara el algoritmo oficial de C14N 1.0:
  ///   http://www.w3.org/TR/2001/REC-xml-c14n-20010315
  /// porque es el requerido por la especificación de firma de e-CF de la DGII.
  ///
  /// Esta implementación cubre el subconjunto de XML que produce FiscoGest
  /// (documentos e-CF y el SignedInfo). No pretende ser una implementación
  /// completa de C14N 1.0 (no procesa comentarios, PIs ni todos los casos
  /// de namespaces heredados complejos).
  ///
  /// El mismo algoritmo se aplica tanto al documento como al SignedInfo
  /// para garantizar consistencia entre DigestValue y SignatureValue.
  static const String _c14nAlgorithm =
      'http://www.w3.org/TR/2001/REC-xml-c14n-20010315';

  /// Canonicalización XML C14N 1.0 inclusiva, compartida por
  /// digest del documento y firma de SignedInfo.
  static String _canon(String xml) {
    final document = XmlDocument.parse(xml);
    final algorithm = SignedXml.canonicalizationAlgorithms[_c14nAlgorithm];

    if (algorithm == null) {
      throw StateError('No está disponible el algoritmo XML C14N 1.0');
    }

    final canonical = algorithm.process(document.rootElement);
    if (canonical is! String) {
      throw StateError('El canonicalizador no devolvió texto XML');
    }
    return canonical;
  }

  static String _insertSignature(String xml, String signatureXml) {
    final documento = XmlDocument.parse(xml);
    final firma = XmlDocument.parse(signatureXml);

    final raizFirma = firma.rootElement;

    if (raizFirma.name.local != 'Signature' ||
        raizFirma.namespaceUri != _xmlDsigNamespace) {
      throw const FormatException(
        'El nodo proporcionado no es una firma XMLDSig válida.',
      );
    }

    documento.rootElement.children.add(raizFirma.copy());

    return documento.toXmlString(pretty: false);
  }
}

/// Stub seguro cuando no hay certificado configurado.
class NoOpEcfeSigner implements EcfeSigner {
  @override
  Future<String> firmar(String xmlSinFirma) async {
    throw StateError(
      'Firma no disponible: configura certificado .p12 y clave en e-CF → Configuración',
    );
  }
}
