import 'package:fiscogest_rd/features/e_cf/domain/enums/tipo_ecf.dart';
import 'package:fiscogest_rd/features/e_cf/domain/services/rfce_rules.dart';

/// Arma el resumen a partir del e-CF 32 ya firmado.
class RfceXml {
  static bool esResumenConsumo(String xmlEcf) {
    if (xmlEcf.contains('<RFCE')) return false;
    final total = double.tryParse(_texto(xmlEcf, 'MontoTotal')) ?? 0;
    final tipo = _texto(xmlEcf, 'TipoeCF') == '32'
        ? TipoEcf.facturaConsumo
        : TipoEcf.facturaCreditoFiscal;
    return tipo == TipoEcf.facturaConsumo &&
        RfceRules.esCandidatoRfce(tipo: tipo, total: total);
  }

  static String desdeEcfFirmado(String xmlEcf, String codigo) {
    String elem(String nombre) {
      final valor = _texto(xmlEcf, nombre);
      if (valor.isEmpty) return '';
      return '<$nombre>$valor</$nombre>';
    }

    String bloque(List<String> partes) =>
        partes.where((e) => e.isNotEmpty).join();

    final comprador = bloque([
      elem('RNCComprador'),
      elem('RazonSocialComprador'),
    ]);
    return '<?xml version="1.0" encoding="UTF-8"?>'
        '<RFCE><Encabezado>'
        '<Version>1.0</Version>'
        '<IdDoc>${bloque([elem('TipoeCF'), elem('eNCF'), elem('TipoIngresos'), elem('TipoPago')])}</IdDoc>'
        '<Emisor>${bloque([elem('RNCEmisor'), elem('RazonSocialEmisor'), elem('FechaEmision')])}</Emisor>'
        "${comprador.isEmpty ? '' : '<Comprador>$comprador</Comprador>'}"
        '<Totales>${_interior(xmlEcf, 'Totales')}</Totales>'
        '<CodigoSeguridadeCF>${codigo.trim()}</CodigoSeguridadeCF>'
        '</Encabezado></RFCE>';
  }

  static String _texto(String xml, String tag) {
    final m = RegExp(
      '<$tag\\b[^>]*>([^<]*)</$tag>',
      caseSensitive: false,
    ).firstMatch(xml);
    return (m?.group(1) ?? '').trim();
  }

  static String _interior(String xml, String tag) {
    final m = RegExp(
      '<$tag\\b[^>]*>([\\s\\S]*?)</$tag>',
      caseSensitive: false,
    ).firstMatch(xml);
    return (m?.group(1) ?? '').replaceAll(RegExp(r'\s+'), '');
  }
}
