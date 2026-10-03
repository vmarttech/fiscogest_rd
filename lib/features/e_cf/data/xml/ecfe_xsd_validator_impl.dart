import 'dart:io';

import 'package:fiscogest_rd/features/e_cf/domain/ports/ecfe_xsd_validator.dart';
import 'package:xml/xml.dart';

/// Validación e-CF:
/// 1) XML bien formado + reglas estructurales internas.
/// 2) Si [rutaXsd] apunta a un .xsd (o directorio con un .xsd raíz),
///    valida con `xmllint --schema` (libxml2).
class EcfeXsdValidatorImpl implements EcfeXsdValidator {
  EcfeXsdValidatorImpl({
    this.rutaXsd,
    this.exigirXsd = false,
  });

  /// Ruta a archivo .xsd o carpeta que lo contiene.
  final String? rutaXsd;

  /// Si true, falla cuando no hay XSD usable o xmllint no está disponible.
  final bool exigirXsd;

  static final _encfRe = RegExp(r'^E(31|32|33|34|41|43|44|45|46|47)\d{10}$');
  static final _fechaRe = RegExp(r'^\d{2}-\d{2}-\d{4}$');

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

    _validarEstructura(doc, errores);

    final xsdFile = await _resolverArchivoXsd();
    if (xsdFile == null) {
      if (exigirXsd) {
        errores.add(
          'XSD oficial no configurado o no encontrado. '
          'Indica la ruta del .xsd DGII en e-CF → Configuración.',
        );
      }
    } else {
      final xsdErr = await _validarConXmllint(xml, xsdFile);
      errores.addAll(xsdErr);
    }

    return errores.isEmpty
        ? const EcfeXsdResultado(ok: true)
        : EcfeXsdResultado(ok: false, errores: errores);
  }

  void _validarEstructura(XmlDocument doc, List<String> errores) {
    final root = doc.rootElement;
    if (root.name.local != 'ECF') {
      errores.add('Raíz debe ser <ECF>, encontrado <${root.name.local}>');
      return;
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
        if (encf.isNotEmpty && !_encfRe.hasMatch(encf)) {
          errores.add(
            'eNCF inválido (esperado E + tipo + 10 dígitos): $encf',
          );
        }
        final tipo =
            idDoc.findElements('TipoeCF').firstOrNull?.innerText.trim() ?? '';
        if (tipo.isNotEmpty && encf.isNotEmpty && !encf.startsWith('E$tipo')) {
          errores.add('eNCF $encf no coincide con TipoeCF $tipo');
        }
        _req(idDoc, 'FechaVencimientoSecuencia', errores);
        final fvs = idDoc
                .findElements('FechaVencimientoSecuencia')
                .firstOrNull
                ?.innerText
                .trim() ??
            '';
        if (fvs.isNotEmpty && !_fechaRe.hasMatch(fvs)) {
          errores.add(
            'FechaVencimientoSecuencia debe ser dd-MM-yyyy: $fvs',
          );
        }
      }

      final emisor = encabezado.findElements('Emisor').firstOrNull;
      if (emisor == null) {
        errores.add('Falta <Emisor>');
      } else {
        _req(emisor, 'RNCEmisor', errores);
        _req(emisor, 'RazonSocialEmisor', errores);
        _req(emisor, 'FechaEmision', errores);
        final fe =
            emisor.findElements('FechaEmision').firstOrNull?.innerText.trim() ??
                '';
        if (fe.isNotEmpty && !_fechaRe.hasMatch(fe)) {
          errores.add('FechaEmision debe ser dd-MM-yyyy: $fe');
        }
        final rnc =
            emisor.findElements('RNCEmisor').firstOrNull?.innerText.trim() ??
                '';
        final rncDigits = rnc.replaceAll(RegExp(r'\D'), '');
        if (rncDigits.isNotEmpty &&
            rncDigits.length != 9 &&
            rncDigits.length != 11) {
          errores.add('RNCEmisor longitud inválida: $rnc');
        }
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
  }

  Future<File?> _resolverArchivoXsd() async {
    final raw = rutaXsd?.trim() ?? '';
    if (raw.isEmpty) {
      // Convención del proyecto
      for (final c in [
        'assets/ecf_xsd/ECF_v1.0.xsd',
        'assets/ecf_xsd/ECF.xsd',
        'assets/ecf_xsd/ecf.xsd',
      ]) {
        final f = File(c);
        if (await f.exists()) return f;
      }
      final dir = Directory('assets/ecf_xsd');
      if (await dir.exists()) {
        final xsds = dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.xsd'))
            .toList();
        if (xsds.isNotEmpty) return xsds.first;
      }
      return null;
    }

    final f = File(raw);
    if (await f.exists() && raw.toLowerCase().endsWith('.xsd')) {
      return f;
    }
    final d = Directory(raw);
    if (await d.exists()) {
      final xsds = d
          .listSync()
          .whereType<File>()
          .where((x) => x.path.toLowerCase().endsWith('.xsd'))
          .toList();
      if (xsds.isEmpty) return null;
      // Prefer names containing ECF
      xsds.sort((a, b) {
        final as = a.path.toUpperCase().contains('ECF') ? 0 : 1;
        final bs = b.path.toUpperCase().contains('ECF') ? 0 : 1;
        return as.compareTo(bs);
      });
      return xsds.first;
    }
    return null;
  }

  Future<List<String>> _validarConXmllint(String xml, File xsd) async {
    final errores = <String>[];
    final xmllint = await _whichXmllint();
    if (xmllint == null) {
      if (exigirXsd) {
        errores.add(
          'xmllint no está instalado (apt install libxml2-utils). '
          'Requerido para validar XSD oficial.',
        );
      } else {
        errores.add(
          'Aviso: XSD encontrado (${xsd.path}) pero xmllint no está '
          'instalado; solo se aplicó validación estructural interna. '
          'Instala libxml2-utils para validación formal DGII.',
        );
        // Aviso no bloquea si no exigir — quitar de errores y usar info?
        // Para operación seria: si hay XSD configurado, exigir xmllint
        errores.clear();
        errores.add(
          'XSD configurado (${xsd.path}) pero falta xmllint. '
          'Instala: sudo apt-get install -y libxml2-utils',
        );
      }
      return errores;
    }

    final tmp = await File(
      '${Directory.systemTemp.path}/ecfe_val_${DateTime.now().millisecondsSinceEpoch}.xml',
    ).create();
    try {
      await tmp.writeAsString(xml);
      final result = await Process.run(
        xmllint,
        ['--noout', '--schema', xsd.path, tmp.path],
        runInShell: false,
      );
      if (result.exitCode != 0) {
        final err = '${result.stderr}\n${result.stdout}'.trim();
        if (err.isEmpty) {
          errores.add('Validación XSD falló (código ${result.exitCode})');
        } else {
          // Limitar tamaño de mensaje
          final msg = err.length > 1200 ? '${err.substring(0, 1200)}…' : err;
          errores.add('XSD: $msg');
        }
      }
    } catch (e) {
      errores.add('Error ejecutando xmllint: $e');
    } finally {
      try {
        await tmp.delete();
      } catch (_) {}
    }
    return errores;
  }

  Future<String?> _whichXmllint() async {
    try {
      final r = await Process.run('which', ['xmllint']);
      if (r.exitCode == 0) {
        final p = '${r.stdout}'.trim();
        if (p.isNotEmpty) return p;
      }
    } catch (_) {}
    for (final c in ['/usr/bin/xmllint', '/bin/xmllint']) {
      if (await File(c).exists()) return c;
    }
    return null;
  }

  void _req(XmlElement parent, String name, List<String> errores) {
    final el = parent.findElements(name).firstOrNull;
    if (el == null || el.innerText.trim().isEmpty) {
      errores.add('Falta o vacío <$name>');
    }
  }
}
