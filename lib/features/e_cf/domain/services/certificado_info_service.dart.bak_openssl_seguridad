import 'dart:convert';
import 'dart:io';

class CertificadoInfo {
  const CertificadoInfo({this.notAfter, this.error});

  final DateTime? notAfter;
  final String? error;

  bool get legible => notAfter != null && error == null;

  int? get diasRestantes {
    final f = notAfter;
    if (f == null) return null;
    final hoy = DateTime.now();
    final a = DateTime(hoy.year, hoy.month, hoy.day);
    final b = DateTime(f.year, f.month, f.day);
    return b.difference(a).inDays;
  }

  bool get vencido => (diasRestantes ?? 1) < 0;

  bool get requiereAviso {
    final d = diasRestantes;
    if (d == null) return false;
    return d <= 30;
  }

  String get mensaje {
    if (error != null) return error!;
    final d = diasRestantes;
    if (d == null) return 'No se pudo determinar el vencimiento del certificado';
    if (d < 0) return 'Certificado digital VENCIDO hace ${-d} día(s)';
    if (d == 0) return 'Certificado digital vence HOY';
    if (d <= 30) return 'Certificado digital vence en $d día(s)';
    return 'Certificado vigente ($d días restantes)';
  }
}

class CertificadoInfoService {
  static Future<CertificadoInfo> inspeccionar({
    required String ruta,
    required String clave,
  }) async {
    final path = ruta.trim();
    if (path.isEmpty) {
      return const CertificadoInfo(error: 'Sin ruta de certificado');
    }
    if (!await File(path).exists()) {
      return CertificadoInfo(error: 'No existe el archivo: $path');
    }
    try {
      final r = await Process.run(
        'openssl',
        [
          'pkcs12',
          '-in',
          path,
          '-nokeys',
          '-clcerts',
          '-passin',
          'pass:$clave',
        ],
      );
      if (r.exitCode != 0) {
        final err = '${r.stderr}'.trim();
        return CertificadoInfo(
          error: err.isEmpty
              ? 'OpenSSL no pudo leer el .p12 (¿clave incorrecta?)'
              : (err.length > 180 ? '${err.substring(0, 180)}…' : err),
        );
      }
      final pem = '${r.stdout}';
      final r3 = await Process.start('openssl', ['x509', '-noout', '-enddate']);
      r3.stdin.write(pem);
      await r3.stdin.close();
      final out = await r3.stdout.transform(utf8.decoder).join();
      final err2 = await r3.stderr.transform(utf8.decoder).join();
      final code = await r3.exitCode;
      if (code != 0) {
        return CertificadoInfo(
          error: err2.trim().isEmpty
              ? 'No se pudo leer fecha del certificado'
              : err2.trim(),
        );
      }
      final m = RegExp(r'notAfter=(.+)').firstMatch(out.trim());
      if (m == null) {
        return CertificadoInfo(error: 'Fecha no reconocida: ${out.trim()}');
      }
      final parsed = _parseOpenSslDate(m.group(1)!.trim());
      if (parsed == null) {
        return CertificadoInfo(error: 'Fecha no parseable: ${m.group(1)}');
      }
      return CertificadoInfo(notAfter: parsed);
    } catch (e) {
      return CertificadoInfo(error: '$e');
    }
  }

  static DateTime? _parseOpenSslDate(String s) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final parts = s.replaceAll(RegExp(r'\s+'), ' ').split(' ');
    if (parts.length < 4) return null;
    final mon = months[parts[0]];
    final day = int.tryParse(parts[1]);
    final year = int.tryParse(parts[3]);
    final time = parts[2].split(':');
    if (mon == null || day == null || year == null || time.length < 2) {
      return null;
    }
    final h = int.tryParse(time[0]) ?? 0;
    final min = int.tryParse(time[1]) ?? 0;
    final sec = time.length > 2 ? (int.tryParse(time[2]) ?? 0) : 0;
    return DateTime.utc(year, mon, day, h, min, sec).toLocal();
  }
}
