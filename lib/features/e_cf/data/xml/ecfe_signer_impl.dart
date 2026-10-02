import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:fiscogest_rd/features/e_cf/domain/ports/ecfe_signer.dart';
import 'package:xml/xml.dart';

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
      throw StateError(
        'OpenSSL no está en el PATH. Instálalo para firmar e-CF en este equipo.',
      );
    }

    final tmp = await Directory.systemTemp.createTemp('ecfe_sign_');
    try {
      final keyPem = File('${tmp.path}/key.pem');
      final certPem = File('${tmp.path}/cert.pem');
      final p12PassFile = File('${tmp.path}/p12.pass');
      await p12PassFile.writeAsString(claveCertificado, flush: true);

      // Extraer clave privada
      final rKey = await Process.run(openssl, [
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
          'No se pudo leer la clave del .p12 (¿password incorrecta?): ${rKey.stderr}',
        );
      }

      // Extraer certificado X509
      final rCert = await Process.run(openssl, [
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
        throw StateError('No se pudo leer el certificado del .p12: ${rCert.stderr}');
      }

      final x509B64 = _extractCertBase64(await certPem.readAsString());
      if (x509B64.isEmpty) {
        throw StateError('Certificado X509 vacío en el .p12');
      }

      // Documento a firmar: quitar cualquier Signature previa
      final xmlLimpio = _stripSignature(xmlSinFirma.trim());
      final digestValue = base64.encode(sha256.convert(utf8.encode(xmlLimpio)).bytes);

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
      await siFile.writeAsString(signedInfo, flush: true);
      final sigOut = File('${tmp.path}/sig.bin');

      // RSA-SHA256 sobre SignedInfo
      final rSign = await Process.run(openssl, [
        'dgst',
        '-sha256',
        '-sign',
        keyPem.path,
        '-out',
        sigOut.path,
        siFile.path,
      ]);
      if (rSign.exitCode != 0) {
        throw StateError('Error al firmar SignedInfo: ${rSign.stderr}');
      }
      final signatureValue = base64.encode(await sigOut.readAsBytes());

      final signatureXml =
          '<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">'
          '$signedInfo'
          '<SignatureValue>$signatureValue</SignatureValue>'
          '<KeyInfo><X509Data><X509Certificate>$x509B64</X509Certificate></X509Data></KeyInfo>'
          '</Signature>';

      return _insertSignature(xmlLimpio, signatureXml);
    } finally {
      try {
        await tmp.delete(recursive: true);
      } catch (_) {}
    }
  }

  static Future<String?> _whichOpenssl() async {
    final r = await Process.run('which', ['openssl']);
    if (r.exitCode == 0) {
      final p = (r.stdout as String).trim();
      if (p.isNotEmpty) return p;
    }
    // Windows
    final r2 = await Process.run('where', ['openssl']);
    if (r2.exitCode == 0) {
      final lines = (r2.stdout as String).trim().split('\n');
      if (lines.isNotEmpty && lines.first.trim().isNotEmpty) {
        return lines.first.trim();
      }
    }
    return null;
  }

  static String _extractCertBase64(String pem) {
    final lines = pem
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('-----'))
        .toList();
    return lines.join();
  }

  static String _stripSignature(String xml) {
    try {
      final doc = XmlDocument.parse(xml);
      for (final s in doc.findAllElements('Signature').toList()) {
        // Solo xmldsig
        final ns = s.namespaceUri ?? '';
        if (ns.contains('xmldsig') || s.name.local == 'Signature') {
          s.remove();
        }
      }
      return doc.toXmlString(pretty: false);
    } catch (_) {
      // fallback regex
      return xml.replaceAll(
        RegExp(r'<Signature\b[^>]*>[\s\S]*?</Signature>', multiLine: true),
        '',
      );
    }
  }

  static String _insertSignature(String xml, String signatureXml) {
    // Insertar antes del cierre de la raíz (ECF u otra)
    final close = RegExp(r'</([A-Za-z_][\w.-]*)>\s*$');
    final m = close.firstMatch(xml);
    if (m != null) {
      final tag = m.group(1)!;
      final idx = xml.lastIndexOf('</$tag>');
      if (idx >= 0) {
        return '${xml.substring(0, idx)}$signatureXml</$tag>';
      }
    }
    return '$xml$signatureXml';
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
