import 'dart:io';

import 'package:fiscogest_rd/features/e_cf/domain/ports/ecfe_xsd_validator.dart';
import 'package:xml/xml.dart';

class EcfeXsdValidatorImpl implements EcfeXsdValidator {
  EcfeXsdValidatorImpl({this.rutaXsd});
  final String? rutaXsd;

  @override
  Future<EcfeXsdResultado> validar(String xml) async {
    final errores = <String>[];
    if (xml.trim().isEmpty) {
      return const EcfeXsdResultado(ok: false, errores: ['XML vacío']);
    }
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(xml);
    } catch (e) {
      return EcfeXsdResultado(ok: false, errores: ['XML mal formado: $e']);
    }
    final root = doc.rootElement;
    if (root.name.local != 'ECF') {
      errores.add('Raíz debe ser <ECF>, encontrado <${root.name.local}>');
    }
    final encabezado = root.findElements('Encabezado').firstOrNull;
    if (encabezado == null) {
      errores.add('Falta <Encabezado>');
    } else {
      _req(encabezado, 'Version', errores);
      final idDoc = encabezado.findElements('IdDoc').firstOrNull;
      if (idDoc == null) {
        errores.add('Falta <IdDoc>');
      } else {
        _req(idDoc, 'TipoeCF', errores);
        _req(idDoc, 'eNCF', errores);
        final encf =
            idDoc.findElements('eNCF').firstOrNull?.innerText.trim() ?? '';
        if (encf.isNotEmpty &&
            !RegExp(r'^E(31|32)\d{10}$').hasMatch(encf)) {
          errores.add(
            'eNCF inválido (esperado E31/E32 + 10 dígitos): $encf',
          );
        }
        _req(idDoc, 'FechaVencimientoSecuencia', errores);
      }
      final emisor = encabezado.findElements('Emisor').firstOrNull;
      if (emisor == null) {
        errores.add('Falta <Emisor>');
      } else {
        _req(emisor, 'RNCEmisor', errores);
        _req(emisor, 'RazonSocialEmisor', errores);
        _req(emisor, 'FechaEmision', errores);
      }
      final totales = encabezado.findElements('Totales').firstOrNull;
      if (totales == null) {
        errores.add('Falta <Totales>');
      } else {
        _req(totales, 'MontoTotal', errores);
      }
    }
    final detalles = root.findElements('DetallesItems').firstOrNull;
    if (detalles == null) {
      errores.add('Falta <DetallesItems>');
    } else {
      final items = detalles.findElements('Item').toList();
      if (items.isEmpty) errores.add('Debe haber al menos un <Item>');
      for (var i = 0; i < items.length; i++) {
        final it = items[i];
        if (it.findElements('NumeroLinea').isEmpty) {
          errores.add('Item[$i]: falta NumeroLinea');
        }
        if (it.findElements('NombreItem').isEmpty) {
          errores.add('Item[$i]: falta NombreItem');
        }
        if (it.findElements('MontoItem').isEmpty) {
          errores.add('Item[$i]: falta MontoItem');
        }
      }
    }
    final ruta = rutaXsd?.trim();
    if (ruta != null && ruta.isNotEmpty) {
      if (!await File(ruta).exists()) {
        errores.add('XSD no encontrado en: $ruta');
      }
    }
    return errores.isEmpty
        ? const EcfeXsdResultado(ok: true)
        : EcfeXsdResultado(ok: false, errores: errores);
  }

  void _req(XmlElement parent, String name, List<String> errores) {
    final el = parent.findElements(name).firstOrNull;
    if (el == null || el.innerText.trim().isEmpty) {
      errores.add('Falta o vacío <$name>');
    }
  }
}
