import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:fiscogest_rd/features/e_cf/data/gateways/dgii_endpoints.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/ambiente_dgii.dart';

/// Código de seguridad para Representación Impresa (RI) y QR.
///
/// 1. Preferir valor persistido (oficial DGII o calculado al firmar).
/// 2. Si no hay, derivar 6 caracteres del SignatureValue del XML firmado
///    (SHA-256 hex mayúsculas) — estable para reimpresiones.
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

  /// Resuelve el código a mostrar/imprimir.
  static String resolver({
    String? codigoPersistido,
    String? xmlFirmado,
  }) {
    final p = (codigoPersistido ?? '').trim();
    if (p.isNotEmpty) return p.toUpperCase();
    final xml = (xmlFirmado ?? '').trim();
    if (xml.isNotEmpty) return desdeXmlFirmado(xml);
    return '------';
  }

  /// URL de consulta pública del timbre (misma base por ambiente que APIs).
  static String urlConsulta({
    required AmbienteDgii ambiente,
    required String rncEmisor,
    required String encf,
    required String codigoSeguridad,
  }) {
    final base = DgiiEndpoints.baseEcf(ambiente);
    final root = base.isEmpty
        ? 'https://ecf.dgii.gov.do/testecf'
        : base;
    final q = Uri(
      queryParameters: {
        'RncEmisor': rncEmisor.replaceAll(RegExp(r'\D'), ''),
        'ENCF': encf.trim().toUpperCase(),
        'CodigoSeguridad': codigoSeguridad.trim().toUpperCase(),
      },
    );
    return '$root/ConsultaTimbre?${q.query}';
  }
}
