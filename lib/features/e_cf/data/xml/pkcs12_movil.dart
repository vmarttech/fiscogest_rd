
import 'package:flutter/services.dart';

class FirmaPkcs12 {
  const FirmaPkcs12({required this.certificado, required this.firma});
  final String certificado;
  final String firma;
}

class Pkcs12Movil {
  static const _canal = MethodChannel('fiscogest/pkcs12');

  static Future<FirmaPkcs12> firmar({
    required String ruta,
    required String clave,
    required Uint8List datos,
  }) async {
    final r = await _canal.invokeMapMethod<String, String>('firmar', {
      'ruta': ruta,
      'clave': clave,
      'datos': datos,
    });
    final cert = (r?['certificado'] ?? '').trim();
    final firma = (r?['firma'] ?? '').trim();
    if (cert.isEmpty || firma.isEmpty) {
      throw StateError('El telefono no pudo leer el certificado .p12');
    }
    return FirmaPkcs12(certificado: cert, firma: firma);
  }
}
