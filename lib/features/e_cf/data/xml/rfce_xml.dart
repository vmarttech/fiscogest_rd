import 'package:xml/xml.dart' as xml;

import 'package:fiscogest_rd/features/e_cf/domain/enums/tipo_ecf.dart';
import 'package:fiscogest_rd/features/e_cf/domain/services/rfce_rules.dart';

/// Arma el resumen a partir del e-CF 32 ya firmado.
class RfceXml {
  static bool esResumenConsumo(String xmlEcf) {
    try {
      final documento = xml.XmlDocument.parse(xmlEcf);

      if (documento.findAllElements('RFCE').isNotEmpty) {
        return false;
      }

      final total = double.tryParse(_texto(documento, 'MontoTotal')) ?? 0;

      final tipo = _texto(documento, 'TipoeCF') == '32'
          ? TipoEcf.facturaConsumo
          : TipoEcf.facturaCreditoFiscal;

      return tipo == TipoEcf.facturaConsumo &&
          RfceRules.esCandidatoRfce(tipo: tipo, total: total);
    } catch (_) {
      return false;
    }
  }

  static String desdeEcfFirmado(String xmlEcf, String codigo) {
    final documento = xml.XmlDocument.parse(xmlEcf);

    String elem(String nombre) {
      final valor = _texto(documento, nombre);
      if (valor.isEmpty) return '';

      // XmlText escapa &, < y otros caracteres especiales.
      final textoSeguro = xml.XmlText(valor).toXmlString();

      return '<$nombre>$textoSeguro</$nombre>';
    }

    String bloque(List<String> partes) =>
        partes.where((e) => e.isNotEmpty).join();

    final comprador = bloque([
      elem('RNCComprador'),
      elem('RazonSocialComprador'),
    ]);

    final codigoSeguro = xml.XmlText(codigo.trim()).toXmlString();

    return '<?xml version="1.0" encoding="UTF-8"?>'
        '<RFCE><Encabezado>'
        '<Version>1.0</Version>'
        '<IdDoc>${bloque([elem('TipoeCF'), elem('eNCF'), elem('TipoIngresos'), elem('TipoPago')])}</IdDoc>'
        '<Emisor>${bloque([elem('RNCEmisor'), elem('RazonSocialEmisor'), elem('FechaEmision')])}</Emisor>'
        '${comprador.isEmpty ? '' : '<Comprador>$comprador</Comprador>'}'
        '<Totales>${_interior(documento, 'Totales')}</Totales>'
        '<CodigoSeguridadeCF>$codigoSeguro</CodigoSeguridadeCF>'
        '</Encabezado></RFCE>';
  }

  static String _texto(xml.XmlDocument documento, String tag) {
    final elementos = documento.findAllElements(tag);

    for (final elemento in elementos) {
      return elemento.innerText.trim();
    }

    return '';
  }

  static String _interior(xml.XmlDocument documento, String tag) {
    for (final elemento in documento.findAllElements(tag)) {
      // Conserva nodos de texto, espacios, elementos y contenido.
      return elemento.children.map((nodo) => nodo.toXmlString()).join();
    }

    return '';
  }
}
