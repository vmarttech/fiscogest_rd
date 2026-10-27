import 'dart:io';

import 'package:fiscogest_rd/features/e_cf/domain/entities/ecfe_config.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/ambiente_dgii.dart';

/// Resultado de comprobaciones previas a generar / firmar / enviar.
class EcfePreflightResultado {
  const EcfePreflightResultado({
    required this.ok,
    this.errores = const [],
    this.avisos = const [],
  });

  final bool ok;
  final List<String> errores;
  final List<String> avisos;

  bool get bloqueante => !ok;
}

/// Validaciones de robustez comercial antes del pipeline e-CF.
///
/// No contacta DGII. Solo comprueba configuración local y entorno.
class EcfePreflight {
  /// [exigirXsdArchivo] si true, exige ruta XSD usable en disco.
  static Future<EcfePreflightResultado> evaluar(
    EcfeConfig cfg, {
    bool exigirOpensslEnEscritorio = true,
    bool exigirXsdArchivo = false,
  }) async {
    final errores = <String>[];
    final avisos = <String>[];

    if (cfg.ambiente == AmbienteDgii.deshabilitado) {
      errores.add('Módulo e-CF deshabilitado (ambiente).');
    }
    if (cfg.rncEmisor.trim().isEmpty) {
      errores.add('RNC emisor no configurado.');
    }
    final rnc = cfg.rncEmisor.replaceAll(RegExp(r'\D'), '');
    if (rnc.isNotEmpty && rnc.length != 9 && rnc.length != 11) {
      errores.add('RNC emisor con longitud inválida ($rnc).');
    }
    if (!cfg.tieneCertificado) {
      errores.add('Certificado .p12/.pfx y clave son obligatorios.');
    } else {
      final f = File(cfg.rutaCertificado.trim());
      if (!await f.exists()) {
        errores.add('No existe el archivo de certificado: ${cfg.rutaCertificado}');
      } else {
        final subjectOk = await _certificadoCoincideConRnc(
          ruta: cfg.rutaCertificado.trim(),
          clave: cfg.claveCertificado,
          rncEmisor: cfg.rncEmisor,
        );
        if (subjectOk == false) {
          // false = se pudo leer y NO coincide; null = no se pudo verificar
          errores.add(
            'El certificado .p12 no parece corresponder al RNC emisor configurado. '
            'DGII exige que el titular del certificado coincida con el emisor.',
          );
        } else if (subjectOk == null) {
          avisos.add(
            'No se pudo verificar el titular del certificado (OpenSSL). '
            'Revise manualmente que el .p12 sea del RNC emisor.',
          );
        }
      }
    }

    // OpenSSL en escritorio (firma real)
    if (exigirOpensslEnEscritorio &&
        !Platform.isAndroid &&
        !Platform.isIOS) {
      final openssl = await _which('openssl');
      if (openssl == null) {
        errores.add(
          'OpenSSL no está en el PATH. Es obligatorio para firmar e-CF en escritorio.',
        );
      }
    }

    final xsd = (cfg.xsdVersion).trim();
    if (exigirXsdArchivo ||
        cfg.ambiente == AmbienteDgii.certificacion ||
        cfg.ambiente == AmbienteDgii.produccion) {
      if (xsd.isEmpty) {
        // Convención de proyecto
        final candidatos = [
          'assets/ecf_xsd/ECF_v1.0.xsd',
          'assets/ecf_xsd/ECF.xsd',
          'assets/ecf_xsd/ecf.xsd',
        ];
        var hay = false;
        for (final c in candidatos) {
          if (await File(c).exists()) {
            hay = true;
            break;
          }
        }
        if (!hay) {
          errores.add(
            'XSD oficial no configurado y no se encontró en assets/ecf_xsd/. '
            'Obligatorio en certificación/producción.',
          );
        }
      } else {
        final f = File(xsd);
        final d = Directory(xsd);
        final okFile = await f.exists() && xsd.toLowerCase().endsWith('.xsd');
        final okDir = await d.exists();
        if (!okFile && !okDir) {
          errores.add('Ruta XSD inválida: $xsd');
        }
      }
      final xmllint = await _which('xmllint');
      if (xmllint == null) {
        errores.add(
          'xmllint no está en el PATH (libxml2). Obligatorio para validar XSD en cert/prod.',
        );
      }
    } else if (xsd.isEmpty) {
      avisos.add('XSD no configurado: solo validación estructural interna.');
    }

    if (cfg.ambiente == AmbienteDgii.produccion) {
      avisos.add(
        'Ambiente PRODUCCIÓN: solo operar con RNC autorizado y certificado del emisor.',
      );
    }

    return EcfePreflightResultado(
      ok: errores.isEmpty,
      errores: errores,
      avisos: avisos,
    );
  }

  static Future<String?> _which(String cmd) async {
    try {
      final r = await Process.run(
        Platform.isWindows ? 'where' : 'which',
        [cmd],
        runInShell: false,
      );
      if (r.exitCode != 0) return null;
      final out = (r.stdout ?? '').toString().trim();
      if (out.isEmpty) return null;
      return out.split('\n').first.trim();
    } catch (_) {
      return null;
    }
  }

  /// true = coincide; false = no coincide; null = no verificable.
  static Future<bool?> _certificadoCoincideConRnc({
    required String ruta,
    required String clave,
    required String rncEmisor,
  }) async {
    final rnc = rncEmisor.replaceAll(RegExp(r'\D'), '');
    if (rnc.isEmpty) return null;
    final openssl = await _which('openssl');
    if (openssl == null) return null;
    try {
      final tmp = await Directory.systemTemp.createTemp('ecfe_pre_');
      try {
        final pass = File('${tmp.path}/p.pass');
        await pass.writeAsString(clave, flush: true);
        final r = await Process.run(
          openssl,
          [
            'pkcs12',
            '-in',
            ruta,
            '-clcerts',
            '-nokeys',
            '-passin',
            'file:${pass.path}',
            '-out',
            '${tmp.path}/c.pem',
          ],
          runInShell: false,
        );
        if (r.exitCode != 0) return null;
        final sub = await Process.run(
          openssl,
          ['x509', '-in', '${tmp.path}/c.pem', '-noout', '-subject'],
          runInShell: false,
        );
        if (sub.exitCode != 0) return null;
        final subject = '${sub.stdout}'.replaceAll(RegExp(r'\s+'), ' ');
        final digits = subject.replaceAll(RegExp(r'\D'), '');
        // Coincidencia si el RNC aparece en el subject (serial/CN/serialNumber).
        if (digits.contains(rnc)) return true;
        if (subject.contains(rnc)) return true;
        return false;
      } finally {
        try {
          await tmp.delete(recursive: true);
        } catch (_) {}
      }
    } catch (_) {
      return null;
    }
  }

}
