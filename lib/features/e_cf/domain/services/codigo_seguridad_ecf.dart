import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/ambiente_dgii.dart';

/// Código de seguridad para RI (6 caracteres) a partir del XML firmado.
/// Heurística estable: SHA-256 del SignatureValue / xml firmado → hex mayúsculas.
class CodigoSeguridadEcf {
  static String desdeXmlFirmado(String xmlFirmado) {
    final m = RegExp(
      r'<SignatureValue[^>]*>([^<]+)</SignatureValue>',
      caseSensitive: false,
    ).firstMatch(xmlFirmado);
    final base = (m?.group(1) ?? xmlFirmado).replaceAll(RegExp(r'\s+'), '');
    final digest = sha256.convert(utf8.encode(base));
    return digest.toString().substring(0, 6).toUpperCase();
  }

  /// URL orientativa de consulta pública (ajustar cuando DGII publique la definitiva del ambiente).
  static String urlConsulta({
    required AmbienteDgii ambiente,
    required String rncEmisor,
    required String encf,
    required String codigoSeguridad,
  }) {
    final base = switch (ambiente) {
      AmbienteDgii.precertificacion =>
        'https://ecf.dgii.gov.do/testecf/ConsultaTimbre',
      AmbienteDgii.certificacion =>
        'https://ecf.dgii.gov.do/certecf/ConsultaTimbre',
      AmbienteDgii.produccion =>
        'https://ecf.dgii.gov.do/ecf/ConsultaTimbre',
      AmbienteDgii.deshabilitado =>
        'https://ecf.dgii.gov.do/testecf/ConsultaTimbre',
    };
    final q = Uri(queryParameters: {
      'RncEmisor': rncEmisor,
      'ENCF': encf,
      'CodigoSeguridad': codigoSeguridad,
    });
    return '$base?${q.query}';
  }
}
