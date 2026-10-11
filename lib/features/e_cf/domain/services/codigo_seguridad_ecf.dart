import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/ambiente_dgii.dart';
import 'package:fiscogest_rd/features/e_cf/domain/services/rfce_rules.dart';

/// Código de seguridad para Representación Impresa (RI) y QR.
///
/// 1. Preferir valor persistido (oficial DGII o calculado al firmar).
/// 2. Si no hay, los 6 primeros caracteres del SignatureValue del e-CF firmado.
class CodigoSeguridadEcf {
  static DateTime fechaDeXml(String xml) {
    final m = RegExp(
      r'<FechaHoraFirma>([^<]+)</FechaHoraFirma>',
    ).firstMatch(xml);
    final partes = RegExp(
      r'(\d{2})-(\d{2})-(\d{4}) (\d{2}):(\d{2}):(\d{2})',
    ).firstMatch((m?.group(1) ?? '').trim());
    if (partes == null) return DateTime.now();
    return DateTime(
      int.parse(partes.group(3)!),
      int.parse(partes.group(2)!),
      int.parse(partes.group(1)!),
      int.parse(partes.group(4)!),
      int.parse(partes.group(5)!),
      int.parse(partes.group(6)!),
    );
  }

  static String soloCodigo(String? raw) {
    final p = (raw ?? '').trim();
    final i = p.indexOf('|');
    return i < 0 ? p : p.substring(0, i);
  }

  static String? fechaEmpaquetada(String? raw) {
    final p = (raw ?? '').trim();
    final i = p.indexOf('|');
    if (i < 0 || i + 1 >= p.length) return null;
    return p.substring(i + 1);
  }

  static String empaquetar(String codigo, DateTime firma) {
    String dos(int n) => n.toString().padLeft(2, '0');
    final fecha =
        '${dos(firma.day)}-${dos(firma.month)}-${firma.year} '
        '${dos(firma.hour)}:${dos(firma.minute)}:${dos(firma.second)}';
    return '${soloCodigo(codigo)}|$fecha';
  }

  static String _enc(String raw) {
    const safe =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~+/';
    final b = StringBuffer();
    for (final u in raw.codeUnits) {
      final ch = String.fromCharCode(u);
      if (ch == ' ') {
        b.write('%20');
      } else if (safe.contains(ch)) {
        b.write(ch);
      } else {
        b.write(Uri.encodeQueryComponent(ch));
      }
    }
    return b.toString();
  }

  static String _q(Map<String, String> pares, List<String> orden) {
    return [
      for (final k in orden)
        if ((pares[k] ?? '').isNotEmpty) '$k=${_enc(pares[k]!)}',
    ].join('&');
  }

  static String desdeXmlFirmado(String xmlFirmado) {
    final m = RegExp(
      r'<SignatureValue[^>]*>([^<]+)</SignatureValue>',
      caseSensitive: false,
    ).firstMatch(xmlFirmado);
    final firma = (m?.group(1) ?? '').replaceAll(RegExp(r'\s+'), '');
    if (firma.length >= 6) return firma.substring(0, 6);
    final digest = sha256.convert(utf8.encode(xmlFirmado));
    return digest.toString().substring(0, 6).toUpperCase();
  }

  /// Resuelve el código a mostrar/imprimir.
  static String resolver({String? codigoPersistido, String? xmlFirmado}) {
    final p = (codigoPersistido ?? '').trim();
    if (p.isNotEmpty) return soloCodigo(p);
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
    String? xmlFirmado,
    double? montoTotal,
    String? rncComprador,
    String? fechaEmision,
    String? fechaFirma,
    bool? resumenConsumo,
  }) {
    String tag(String nombre) {
      final xml = xmlFirmado ?? '';
      final m = RegExp(
        '<$nombre\\b[^>]*>([^<]*)</$nombre>',
        caseSensitive: false,
      ).firstMatch(xml);
      return (m?.group(1) ?? '').trim();
    }

    final rnc = (rncEmisor.trim().isNotEmpty ? rncEmisor : tag('RNCEmisor'))
        .replaceAll(RegExp(r'\D'), '');
    final comprador =
        ((rncComprador ?? '').trim().isNotEmpty
                ? rncComprador!
                : tag('RNCComprador'))
            .replaceAll(RegExp(r'\D'), '');
    final ncf = (encf.trim().isNotEmpty ? encf : tag('eNCF'))
        .trim()
        .toUpperCase();
    final emision = (fechaEmision ?? '').trim().isNotEmpty
        ? fechaEmision!.trim()
        : tag('FechaEmision');
    final firma = (fechaFirma ?? '').trim().isNotEmpty
        ? fechaFirma!.trim()
        : (fechaEmpaquetada(codigoSeguridad) ?? '');
    final montoTxt = tag('MontoTotal');
    final monto = montoTotal ?? double.tryParse(montoTxt) ?? 0;
    final tipo = tag('TipoeCF');
    final resumen =
        resumenConsumo ??
        ((xmlFirmado ?? '').contains('<RFCE') ||
            (tipo == '32' && monto < RfceRules.topeDop));
    final slug = switch (ambiente) {
      AmbienteDgii.precertificacion => 'testecf',
      AmbienteDgii.certificacion => 'certecf',
      AmbienteDgii.produccion => 'ecf',
      AmbienteDgii.deshabilitado => 'testecf',
    };
    final codigo = soloCodigo(codigoSeguridad);
    if (resumen) {
      final q = _q(
        {
          'RncEmisor': rnc,
          'ENCF': ncf,
          'MontoTotal': monto.toStringAsFixed(2),
          'CodigoSeguridad': codigo,
        },
        ['RncEmisor', 'ENCF', 'MontoTotal', 'CodigoSeguridad'],
      );
      return 'https://fc.dgii.gov.do/$slug/ConsultaTimbreFC?$q';
    }
    final q = _q(
      {
        'RncEmisor': rnc,
        'RncComprador': comprador,
        'ENCF': ncf,
        'FechaEmision': emision,
        'MontoTotal': monto.toStringAsFixed(2),
        'FechaFirma': firma,
        'CodigoSeguridad': codigo,
      },
      [
        'RncEmisor',
        'RncComprador',
        'ENCF',
        'FechaEmision',
        'MontoTotal',
        'FechaFirma',
        'CodigoSeguridad',
      ],
    );
    return 'https://ecf.dgii.gov.do/$slug/ConsultaTimbre?$q';
  }
}
