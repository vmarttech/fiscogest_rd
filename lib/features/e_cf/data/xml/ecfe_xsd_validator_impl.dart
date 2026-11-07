import 'dart:io';

import 'package:fiscogest_rd/features/e_cf/domain/ports/ecfe_xsd_validator.dart';
import 'package:xml/xml.dart';

/// Validación e-CF:
/// 1) XML bien formado + reglas estructurales internas.
/// 2) Si [rutaXsd] apunta a un .xsd (o directorio con un .xsd raíz),
///    valida con `xmllint --schema` (libxml2).
class EcfeXsdValidatorImpl implements EcfeXsdValidator {
  EcfeXsdValidatorImpl({this.rutaXsd, this.exigirXsd = false});

  /// Ruta a archivo .xsd o carpeta que lo contiene.
  final String? rutaXsd;

  /// Si true, exige XSD usable y (en escritorio) xmllint disponible.
  /// Si false, la ausencia de XSD o de xmllint no es error bloqueante:
  /// se aplica solo la validación estructural interna.
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
    final rootName = doc.rootElement.name.local;
    final tipo = doc.rootElement
            .findAllElements('TipoeCF')
            .map((e) => e.innerText.trim())
            .where((t) => t.isNotEmpty)
            .firstOrNull ??
        '';
    final xsdFile = await _resolverArchivoXsd(
      raiz: rootName,
      tipoEcf: tipo,
    );
    if (xsdFile == null) {
      if (exigirXsd) {
        errores.add(
          'XSD oficial no configurado o no encontrado'
          '${tipo.isNotEmpty ? ' para tipo $tipo' : ''}. '
          'Indica la ruta del .xsd DGII (archivo o carpeta) en e-CF → Configuración.',
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
    final raiz = root.name.local;

    if (raiz != 'ECF' && raiz != 'RFCE') {
      errores.add(
        'Raíz debe ser <ECF> o <RFCE>, encontrado <$raiz>',
      );
      return;
    }

    final esRfce = raiz == 'RFCE';

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
          errores.add('eNCF inválido (esperado E + tipo + 10 dígitos): $encf');
        }
        final tipo =
            idDoc.findElements('TipoeCF').firstOrNull?.innerText.trim() ?? '';
        if (tipo.isNotEmpty && encf.isNotEmpty && !encf.startsWith('E$tipo')) {
          errores.add('eNCF $encf no coincide con TipoeCF $tipo');
        }

        // FechaVencimientoSecuencia:
        // - No aplica a RFCE (resumen de consumo).
        // - Tipo 34 (Nota de Crédito): el generador no la emite.
        if (!esRfce && tipo != '34') {
          _req(idDoc, 'FechaVencimientoSecuencia', errores);
        }
        final fvs = idDoc
                .findElements('FechaVencimientoSecuencia')
                .firstOrNull
                ?.innerText
                .trim() ??
            '';
        if (fvs.isNotEmpty && !_fechaRe.hasMatch(fvs)) {
          errores.add('FechaVencimientoSecuencia debe ser dd-MM-yyyy: $fvs');
        }

        if (esRfce) {
          _req(idDoc, 'TipoPago', errores);
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

    // DetallesItems solo aplica a ECF completo, no al resumen RFCE.
    if (!esRfce) {
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
  }

  /// Resuelve el archivo XSD aplicable al documento.
  ///
  /// Prioridad:
  /// 1. Si [rutaXsd] es un archivo .xsd concreto → se usa tal cual.
  /// 2. Si es carpeta (o vacío → assets/ecf_xsd): se elige por tipo de e-CF
  ///    o RFCE según patrones de nombre habituales del paquete DGII.
  /// 3. Solo como último recurso se usa un esquema genérico ECF*.xsd.
  ///
  /// No se devuelve un .xsd arbitrario “el primero del directorio” cuando
  /// se conoce el tipo: eso produciría validaciones incorrectas.
  Future<File?> _resolverArchivoXsd({
    String raiz = 'ECF',
    String tipoEcf = '',
  }) async {
    final raw = rutaXsd?.trim() ?? '';

    Future<File?> buscarEnDirectorio(Directory dir) async {
      if (!await dir.exists()) return null;
      final xsds = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.xsd'))
          .toList();
      if (xsds.isEmpty) return null;

      String nombre(File f) => f.uri.pathSegments.last.toLowerCase();

      // RFCE tiene esquema propio.
      if (raiz.toUpperCase() == 'RFCE') {
        for (final f in xsds) {
          final n = nombre(f);
          if (n.contains('rfce')) return f;
        }
      }

      // Preferir coincidencia por tipo (31, 32, 33, 34, 41, 43, …).
      if (tipoEcf.isNotEmpty) {
        final t = tipoEcf;
        final patrones = <String>[
          'ecf_$t',
          'ecf$t',
          'e-cf_$t',
          'e-cf$t',
          'e_cf_$t',
          '_$t.',
          '_${t}_',
          'tipo$t',
          'tipoe$t',
        ];
        for (final f in xsds) {
          final n = nombre(f);
          if (patrones.any(n.contains)) return f;
        }
      }

      // Genéricos conocidos del proyecto / paquete DGII.
      const genericos = [
        'ecf_v1.0.xsd',
        'ecf.xsd',
        'ecf_v1.xsd',
      ];
      for (final g in genericos) {
        for (final f in xsds) {
          if (nombre(f) == g) return f;
        }
      }

      // Último recurso solo si no hay tipo conocido.
      if (tipoEcf.isEmpty && raiz.toUpperCase() != 'RFCE') {
        xsds.sort((a, b) {
          final an = nombre(a);
          final bn = nombre(b);
          final scoreA = an.contains('ecf') && !an.contains('rfce') ? 0 : 1;
          final scoreB = bn.contains('ecf') && !bn.contains('rfce') ? 0 : 1;
          return scoreA.compareTo(scoreB);
        });
        return xsds.first;
      }

      // Tipo conocido pero sin XSD específico: no adivinar.
      return null;
    }

    if (raw.isEmpty) {
      for (final c in [
        'assets/ecf_xsd/ECF_v1.0.xsd',
        'assets/ecf_xsd/ECF.xsd',
        'assets/ecf_xsd/ecf.xsd',
      ]) {
        final f = File(c);
        if (await f.exists()) return f;
      }
      return buscarEnDirectorio(Directory('assets/ecf_xsd'));
    }

    final f = File(raw);
    if (await f.exists() && raw.toLowerCase().endsWith('.xsd')) {
      return f;
    }

    final d = Directory(raw);
    if (await d.exists()) {
      return buscarEnDirectorio(d);
    }
    return null;
  }

  Future<List<String>> _validarConXmllint(String xml, File xsd) async {
    final errores = <String>[];
    final xmllint = await _whichXmllint();
    if (xmllint == null) {
      final esMovil = Platform.isAndroid || Platform.isIOS;
      if (esMovil) {
        // En Android/iOS no existe xmllint de forma estándar.
        // Se mantiene la validación estructural interna (ya ejecutada).
        // No se bloquea el flujo de certificación/producción en móviles.
        return const <String>[];
      }
      if (exigirXsd) {
        errores.add(
          'xmllint no está instalado o no está en el PATH. '
          'Linux: apt install libxml2-utils. '
          'Windows: instale xmllint (libxml2) y agréguelo al PATH. '
          'Requerido para validar XSD oficial en escritorio.',
        );
      }
      // En escritorio sin exigirXsd: no se añade error bloqueante.
      return errores;
    }

    final tmp = await File(
      '${Directory.systemTemp.path}/ecfe_val_${DateTime.now().millisecondsSinceEpoch}.xml',
    ).create();
    try {
      await tmp.writeAsString(xml);
      final result = await Process.run(xmllint, [
        '--noout',
        '--schema',
        xsd.path,
        tmp.path,
      ], runInShell: false);
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
    // Linux/macOS
    try {
      final r = await Process.run('which', ['xmllint']);
      if (r.exitCode == 0) {
        final p = '${r.stdout}'.trim().split('\n').first.trim();
        if (p.isNotEmpty) return p;
      }
    } catch (_) {}
    // Windows
    try {
      final r = await Process.run('where', ['xmllint']);
      if (r.exitCode == 0) {
        final p = '${r.stdout}'.trim().split(RegExp(r'\r?\n')).first.trim();
        if (p.isNotEmpty) return p;
      }
    } catch (_) {}
    try {
      final r = await Process.run('where', ['xmllint.exe']);
      if (r.exitCode == 0) {
        final p = '${r.stdout}'.trim().split(RegExp(r'\r?\n')).first.trim();
        if (p.isNotEmpty) return p;
      }
    } catch (_) {}
    for (final c in [
      '/usr/bin/xmllint',
      '/bin/xmllint',
      r'C:\Program Files\libxml2\bin\xmllint.exe',
      r'C:\tools\libxml2\bin\xmllint.exe',
    ]) {
      if (await File(c).exists()) return c;
    }
    // Último intento: comando en PATH
    try {
      final r = await Process.run('xmllint', ['--version']);
      if (r.exitCode == 0 || '${r.stdout}${r.stderr}'.contains('libxml')) {
        return 'xmllint';
      }
    } catch (_) {}
    return null;
  }

  void _req(XmlElement parent, String name, List<String> errores) {
    final el = parent.findElements(name).firstOrNull;
    if (el == null || el.innerText.trim().isEmpty) {
      errores.add('Falta o vacío <$name>');
    }
  }
}
