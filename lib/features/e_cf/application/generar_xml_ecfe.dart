import 'dart:convert';
import 'package:xml/xml.dart' as xml;
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/features/e_cf/data/repositories/ecfe_repository.dart';
import 'package:fiscogest_rd/features/e_cf/data/repositories/ecfe_secuencia_service.dart';
import 'package:fiscogest_rd/features/e_cf/data/xml/ecfe_xml_builder_impl.dart';
import 'package:fiscogest_rd/features/e_cf/data/xml/ecfe_xsd_validator_impl.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/estado_ecf_interno.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/tipo_ecf.dart';
import 'package:fiscogest_rd/features/e_cf/domain/value_objects/ecfe_payload.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/impuestos/domain/services/resolver_tasa_itbis.dart';
import 'package:fiscogest_rd/features/e_cf/domain/services/ecfe_preflight.dart';

class GenerarXmlResultado {
  const GenerarXmlResultado({
    required this.ok,
    this.xml,
    this.encf,
    this.errores = const [],
  });
  final bool ok;
  final String? xml;
  final String? encf;
  final List<String> errores;
}

class GenerarXmlEcfe {
  GenerarXmlEcfe({
    required this.repo,
    required this.secuencias,
    required this.builder,
  });

  final EcfeRepository repo;
  final EcfeSecuenciaService secuencias;
  final EcfeXmlBuilderImpl builder;

  Future<GenerarXmlResultado> call({
    required int documentoId,
    required Venta venta,
    required List<DetalleVenta> detalles,
    required String rncEmisor,
    required String razonSocialEmisor,
    required String direccionEmisor,
    String? telefonoEmisor,
    String? correoEmisor,
    String rncCliente = '',
    String nombreCliente = '',
    double tasaItbis = 18.0,
    String? rutaXsd,
    bool exigirXsd = false,
  }) async {
    var codigoModificacionNota = '3';
    String? encfFinal; // H-19.2: debe estar fuera del try para usarlo en catch
    try {
      final cfgPre = await repo.obtenerConfig();
      final preGen = await EcfePreflight.evaluar(cfgPre);
      if (preGen.bloqueante) {
        return GenerarXmlResultado(ok: false, errores: preGen.errores);
      }
      final doc = await repo.obtenerPorId(documentoId);
      if (doc == null) {
        return const GenerarXmlResultado(
          ok: false,
          errores: ['Documento e-CF no encontrado'],
        );
      }
      final lineasGuardadas =
          (doc.tipoEcf == TipoEcf.notaCredito ||
              doc.tipoEcf == TipoEcf.notaDebito)
          ? _lineasGuardadas(doc.notaFiscalJson, doc.ventaId)
          : null;

      // Catálogo completo DGII de tipos e-CF admitidos en generación.
      const tiposSoportados = {
        TipoEcf.facturaCreditoFiscal, // 31
        TipoEcf.facturaConsumo, // 32
        TipoEcf.notaDebito, // 33
        TipoEcf.notaCredito, // 34
        TipoEcf.compras, // 41
        TipoEcf.gastosMenores, // 43
        TipoEcf.regimenesEspeciales, // 44
        TipoEcf.gubernamental, // 45
        TipoEcf.exportacion, // 46
        TipoEcf.pagosExterior, // 47
      };
      if (!tiposSoportados.contains(doc.tipoEcf)) {
        return GenerarXmlResultado(
          ok: false,
          errores: [
            'Tipo ${doc.tipoEcf.codigo} no soportado en generación XML '
                '(soportados: 31, 32, 33, 34, 41, 43, 44, 45, 46, 47)',
          ],
        );
      }
      if (detalles.isEmpty) {
        return const GenerarXmlResultado(
          ok: false,
          errores: ['La venta no tiene líneas de detalle'],
        );
      }

      if (doc.tipoEcf == TipoEcf.notaCredito ||
          doc.tipoEcf == TipoEcf.notaDebito) {
        final ref = (doc.encfReferencia ?? '').trim();
        if ((doc.tipoEcf == TipoEcf.notaCredito ||
                doc.tipoEcf == TipoEcf.notaDebito) &&
            ref.isEmpty) {
          throw StateError(
            'La nota no tiene el e-NCF de la factura original. No se genera el XML.',
          );
        }
        if (doc.tipoEcf == TipoEcf.notaCredito ||
            doc.tipoEcf == TipoEcf.notaDebito) {
          final totalNota = _montoNotaFiscal(doc.notaFiscalJson);
          double? totalFactura;
          if (doc.ventaId != null) {
            final hermanos = await repo.listarPorVentaId(doc.ventaId!);
            for (final previo in hermanos) {
              final esFactura =
                  previo.tipoEcf != TipoEcf.notaCredito &&
                  previo.tipoEcf != TipoEcf.notaDebito;
              final encfPrevio = (previo.encf ?? '').trim().toUpperCase();
              if (!esFactura || encfPrevio != ref.toUpperCase()) continue;
              if (previo.estado == EstadoEcfInterno.rechazado) {
                throw StateError(
                  'La factura electrónica fue rechazada. No se genera la nota contra un e-NCF rechazado.',
                );
              }
              totalFactura = _montoNotaFiscal(previo.notaFiscalJson);
              break;
            }
          }
          if (totalFactura == null && ref.isNotEmpty) {
            totalFactura = _montoTotalXml(await repo.xmlPorEncf(ref));
          }
          if (doc.tipoEcf == TipoEcf.notaCredito &&
              totalNota != null &&
              totalFactura != null &&
              totalFactura > 0 &&
              (totalNota - totalFactura).abs() < 0.02) {
            codigoModificacionNota = '1';
          }
          if (totalNota != null &&
              lineasGuardadas == null &&
              (totalNota - venta.montoTotal).abs() > 0.02) {
            throw StateError(
              'El total de la nota no coincide con la venta usada para armar el XML. No se genera para no enviar el monto de la factura completa.',
            );
          }
        }

        if (ref.isEmpty) {
          final cual = doc.tipoEcf == TipoEcf.notaDebito ? '33' : '34';
          return GenerarXmlResultado(
            ok: false,
            errores: [
              'Nota ($cual): indica el e-NCF de referencia '
                  '(comprobante modificado) en el detalle e-CF',
            ],
          );
        }
      }
      // e-NCF: reutilizar si ya es formal. Si no, se asignará SOLO después de
      // pasar validación XSD (evita quemar secuencia por error de estructura).
      final yaTieneFormal = EcfeSecuenciaService.esEncfFormal(doc.encf);
      final String? encfAsignado = yaTieneFormal
          ? doc.encf!.trim().toUpperCase()
          : null;
      final fmt = DateFormat('dd-MM-yyyy');
      final fechaEmision = fmt.format(
        (doc.tipoEcf == TipoEcf.notaCredito ||
                doc.tipoEcf == TipoEcf.notaDebito)
            ? doc.creadoEn
            : venta.fecha,
      );
      // vencSeq solo se conoce después de consumir la secuencia (post-XSD).
      // Aquí usamos un fallback seguro para el XML temporal de validación.
      final fechaVenc = fmt.format(DateTime(DateTime.now().year + 1, 12, 31));

      final items = <EcfePayloadItem>[];
      // Líneas en 0 y la venta sí cobró ITBIS: documento viejo, una sola tasa.
      final usarTasaDocumento =
          detalles.every((d) => d.tasaImpuesto <= 0.0001) &&
          venta.itbis > 0.009;
      var gravado18 = 0.0;
      var itbis18 = 0.0;
      var gravado16 = 0.0;
      var itbis16 = 0.0;
      var exento = 0.0;
      var gravado0 = 0.0;
      final gravadosCero = await repo.productosGravadosCero(
        detalles.map((d) => d.productoId),
      );
      for (var i = 0; i < (lineasGuardadas ?? detalles).length; i++) {
        final d = (lineasGuardadas ?? detalles)[i];
        final monto = d.subtotalLinea ?? d.subtotal;
        final tasaLinea = usarTasaDocumento ? tasaItbis : d.tasaImpuesto;
        final pct = tasaLinea > 1.5 ? tasaLinea : tasaLinea * 100.0;
        final indFact = indicadorFacturacionDgii(
          tasaLinea,
          gravadoTasaCero: gravadosCero.contains(d.productoId),
        );
        final fr = pct / 100.0;
        if (indFact == '1') {
          gravado18 += monto;
          itbis18 += monto * fr;
        } else if (indFact == '2') {
          gravado16 += monto;
          itbis16 += monto * fr;
        } else if (indFact == '3') {
          gravado0 += monto;
        } else {
          exento += monto;
        }
        final nombre = (d.nombreProducto ?? '').trim();
        items.add(
          EcfePayloadItem(
            numeroLinea: i + 1,
            nombreItem: nombre.isEmpty ? 'Item ${i + 1}' : nombre,
            cantidad: d.cantidad.toDouble(),
            precioUnitario: d.precioUnitario,
            montoItem: monto,
            indicadorFacturacion: indFact,
          ),
        );
      }

      var fechaNcfModificado = '';
      var indicadorNota = '0';
      if (doc.tipoEcf == TipoEcf.notaDebito ||
          doc.tipoEcf == TipoEcf.notaCredito) {
        final original = await repo.fechaVentaPorEncf(doc.encfReferencia ?? '');
        if (original == null) {
          return const GenerarXmlResultado(
            ok: false,
            errores: [
              'No esta en este equipo el comprobante que modifica la nota. '
                  'Genera primero ese e-CF aqui.',
            ],
          );
        }
        fechaNcfModificado = fmt.format(original);
        final hoyNota = DateTime.now();
        final diasNota = DateTime(hoyNota.year, hoyNota.month, hoyNota.day)
            .difference(DateTime(original.year, original.month, original.day))
            .inDays;
        if (diasNota > 30) {
          indicadorNota = '1';
        }
      }
      final tipoPago = venta.formaPago.toLowerCase().contains('cred')
          ? '2'
          : '1';

      final totalGuardado = lineasGuardadas == null
          ? null
          : _montoNotaFiscal(doc.notaFiscalJson);
      if (lineasGuardadas != null && totalGuardado != null) {
        final sumaLineas =
            gravado18 + gravado16 + gravado0 + exento + itbis18 + itbis16;
        final esParcial = (totalGuardado - venta.montoTotal).abs() > 0.02;
        if (esParcial && (sumaLineas - totalGuardado).abs() > 0.05) {
          throw StateError(
            'Las líneas guardadas de la nota no cuadran con su total. No se genera el XML.',
          );
        }
      }
      final totalXml = totalGuardado ?? venta.montoTotal;
      // Placeholder mientras no tengamos e-NCF formal (se reemplaza tras XSD OK)
      final encfParaBuild = encfAsignado ?? 'E${doc.tipoEcf.codigo}0000000000';
      final payload = EcfePayload(
        tipoEcfCodigo: doc.tipoEcf.codigo,
        encf: encfParaBuild,
        encfReferencia: doc.encfReferencia,
        fechaNcfModificado: fechaNcfModificado,
        codigoModificacion: codigoModificacionNota,
        indicadorNotaCredito: indicadorNota,
        razonModificacion: _razonModificacion(codigoModificacionNota),
        fechaVencimientoSecuencia: fechaVenc,
        fechaLimitePago: venta.formaPago.toLowerCase().contains('cred')
            ? fmt.format(venta.vencimiento ?? venta.fecha)
            : '',
        fechaEmision: fechaEmision,
        tipoIngresos: '01',
        tipoPago: tipoPago,
        rncEmisor: rncEmisor.trim(),
        razonSocialEmisor: razonSocialEmisor.trim(),
        direccionEmisor: direccionEmisor.trim().isEmpty
            ? 'N/D'
            : direccionEmisor.trim(),
        telefonoEmisor: telefonoEmisor,
        correoEmisor: correoEmisor,
        rncComprador: () {
          final escrito = rncCliente.trim();
          if (escrito.isNotEmpty) return escrito;
          final guardado = (doc.rncReceptor ?? '').trim();
          return guardado.isEmpty ? null : guardado;
        }(),
        razonSocialComprador: nombreCliente.trim().isEmpty
            ? (venta.nombreCliente ?? 'CONSUMIDOR FINAL')
            : nombreCliente.trim(),
        direccionComprador: venta.clienteDireccion,
        montoGravadoTotal: gravado18 + gravado16 + gravado0,
        totalItbis: itbis18 + itbis16,
        montoTotal: totalXml,
        tasaItbis: gravado18 > 0 ? 18 : (gravado16 > 0 ? 16 : 0),
        montoGravadoI1: gravado18,
        totalItbis1: itbis18,
        montoGravadoI2: gravado16,
        totalItbis2: itbis16,
        montoGravadoI3: gravado0,
        totalItbis3: 0,
        montoExento: exento,
        bandasItbis: true,
        esRfce: false,
        items: items,
        montoPago: totalXml,
      );

      var xml = builder.construirDesdePayload(payload);
      // En certificación/producción el XSD oficial es obligatorio.
      // En pre-certificación se respeta el flag del caller (desarrollo).
      final cfgAmb = await repo.obtenerConfig();
      final exigirXsdEfectivo =
          exigirXsd ||
          cfgAmb.ambiente.name == 'certificacion' ||
          cfgAmb.ambiente.name == 'produccion';
      final val = await EcfeXsdValidatorImpl(
        rutaXsd: rutaXsd,
        exigirXsd: exigirXsdEfectivo,
      ).validar(xml);

      if (!val.ok) {
        // No consumimos secuencia. Guardamos el XML de diagnóstico sin e-NCF formal.
        await repo.guardarXml(
          id: documentoId,
          xmlSinFirma: xml,
          encf: encfAsignado ?? '', // vacío si aún no se consumió secuencia
          estado: EstadoEcfInterno.validacionFallida,
          ultimoError: val.errores.join(' · '),
        );
        await repo.registrarEvento(
          documentoId: documentoId,
          paso: 'validar_estructura',
          ok: false,
          detalle: val.errores.join(' · '),
        );
        return GenerarXmlResultado(
          ok: false,
          xml: xml,
          encf: encfAsignado,
          errores: val.errores,
        );
      }

      // XSD OK → ahora sí consumimos la secuencia (si aún no tenía formal)
      if (encfAsignado == null) {
        final seq = await secuencias.siguiente(doc.tipoEcf);
        encfFinal = seq.encf;
        final venc = seq.vencimiento;
        // Reconstruir el XML con el e-NCF real (el placeholder no se envió)
        final payloadFinal = EcfePayload(
          tipoEcfCodigo: payload.tipoEcfCodigo,
          encf: encfFinal,
          encfReferencia: payload.encfReferencia,
          fechaNcfModificado: payload.fechaNcfModificado,
          codigoModificacion: payload.codigoModificacion,
          indicadorNotaCredito: payload.indicadorNotaCredito,
          razonModificacion: payload.razonModificacion,
          fechaVencimientoSecuencia: venc != null
              ? fmt.format(venc)
              : payload.fechaVencimientoSecuencia,
          fechaLimitePago: payload.fechaLimitePago,
          fechaEmision: payload.fechaEmision,
          tipoIngresos: payload.tipoIngresos,
          tipoPago: payload.tipoPago,
          rncEmisor: payload.rncEmisor,
          razonSocialEmisor: payload.razonSocialEmisor,
          direccionEmisor: payload.direccionEmisor,
          telefonoEmisor: payload.telefonoEmisor,
          correoEmisor: payload.correoEmisor,
          rncComprador: payload.rncComprador,
          razonSocialComprador: payload.razonSocialComprador,
          direccionComprador: payload.direccionComprador,
          montoGravadoTotal: payload.montoGravadoTotal,
          totalItbis: payload.totalItbis,
          montoTotal: payload.montoTotal,
          tasaItbis: payload.tasaItbis,
          montoGravadoI1: payload.montoGravadoI1,
          totalItbis1: payload.totalItbis1,
          montoGravadoI2: payload.montoGravadoI2,
          totalItbis2: payload.totalItbis2,
          montoGravadoI3: payload.montoGravadoI3,
          totalItbis3: payload.totalItbis3,
          montoExento: payload.montoExento,
          bandasItbis: payload.bandasItbis,
          esRfce: payload.esRfce,
          items: payload.items,
          montoPago: payload.montoPago,
        );
        xml = builder.construirDesdePayload(payloadFinal);
      } else {
        encfFinal = encfAsignado;
      }

      // El XML definitivo puede diferir del provisional (e-NCF real y
      // FechaVencimientoSecuencia). Se revalida antes de marcarlo como listo.
      final valFinal = await EcfeXsdValidatorImpl(
        rutaXsd: rutaXsd,
        exigirXsd: exigirXsdEfectivo,
      ).validar(xml);
      if (!valFinal.ok) {
        await repo.guardarXml(
          id: documentoId,
          xmlSinFirma: xml,
          encf: encfFinal,
          estado: EstadoEcfInterno.validacionFallida,
          ultimoError: valFinal.errores.join(' · '),
        );
        await repo.registrarEvento(
          documentoId: documentoId,
          paso: 'validar_estructura',
          ok: false,
          detalle:
              'Validación del XML definitivo falló (secuencia ya consumida): '
              '${valFinal.errores.join(' · ')}',
        );
        return GenerarXmlResultado(
          ok: false,
          xml: xml,
          encf: encfFinal,
          errores: valFinal.errores,
        );
      }

      await repo.guardarXml(
        id: documentoId,
        xmlSinFirma: xml,
        encf: encfFinal,
        estado: EstadoEcfInterno.xmlListo,
        ultimoError: null,
      );
      await repo.registrarEvento(
        documentoId: documentoId,
        paso: 'generar_xml',
        ok: true,
        detalle: 'XML generado $encfFinal',
      );
      await repo.registrarEvento(
        documentoId: documentoId,
        paso: 'validar_estructura',
        ok: true,
        detalle: 'Validación estructural OK (XML definitivo)',
      );
      return GenerarXmlResultado(ok: true, xml: xml, encf: encfFinal);
    } catch (e) {
      // Ajuste comercial H-19.2: si ya se consumió un e-NCF, lo asociamos
      // al documento aunque haya fallado la generación/validación/persistencia.
      // Evita números fiscales "huérfanos".
      try {
        final reservado = encfFinal;
        if (reservado != null && reservado.isNotEmpty) {
          await repo.guardarXml(
            id: documentoId,
            xmlSinFirma: '',
            encf: reservado,
            estado: EstadoEcfInterno.errorTecnico,
            ultimoError: '$e',
          );
          await repo.registrarEvento(
            documentoId: documentoId,
            paso: 'generar_xml',
            ok: false,
            detalle: 'Error tras reservar $reservado: $e',
          );
        } else {
          await repo.actualizarEstado(
            id: documentoId,
            estado: EstadoEcfInterno.errorTecnico,
            ultimoError: '$e',
          );
          await repo.registrarEvento(
            documentoId: documentoId,
            paso: 'generar_xml',
            ok: false,
            detalle: '$e',
          );
        }
      } catch (_) {}
      return GenerarXmlResultado(ok: false, errores: ['$e']);
    }
  }

  /// Recupera líneas de nota fiscal desde JSON persistido.
  ///
  /// Conserva cantidades fraccionarias (no se redondea a entero).
  /// Usa jsonDecode en lugar de regex para tolerar estructuras válidas.
  List<DetalleVenta>? _lineasGuardadas(String? json, int? ventaId) {
    if (json == null || json.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map) return null;
      final rawLineas = decoded['lineas'];
      if (rawLineas is! List || rawLineas.isEmpty) return null;

      final out = <DetalleVenta>[];
      for (final item in rawLineas) {
        if (item is! Map) continue;
        final m = item.cast<String, dynamic>();

        double numOf(String k) {
          final v = m[k];
          if (v is num) return v.toDouble();
          if (v is String) return double.tryParse(v.trim()) ?? 0;
          return 0;
        }

        final nombre = (m['nombre'] ?? '').toString();
        final cantNum = numOf('cantidad');
        final precioNum = numOf('precio');
        final montoNum = numOf('monto');
        final tasaNum = numOf('tasa');

        if (cantNum <= 0 && montoNum == 0) continue;

        out.add(
          DetalleVenta(
            productoId: 0,
            cantidad: cantNum,
            precioUnitario: precioNum,
            subtotal: montoNum,
            nombreProducto: nombre,
            subtotalLinea: montoNum,
            tasaImpuesto: tasaNum,
          ),
        );
      }
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }

  double? _montoNotaFiscal(String? json) {
    if (json == null || json.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(json);

      dynamic buscar(dynamic valor) {
        if (valor is Map) {
          if (valor.containsKey('montoTotal')) {
            return valor['montoTotal'];
          }

          for (final hijo in valor.values) {
            final resultado = buscar(hijo);
            if (resultado != null) return resultado;
          }
        }

        if (valor is List) {
          for (final hijo in valor) {
            final resultado = buscar(hijo);
            if (resultado != null) return resultado;
          }
        }

        return null;
      }

      final valor = buscar(decoded);

      if (valor is num) return valor.toDouble();

      if (valor is String) {
        return double.tryParse(valor.trim());
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  double? _montoTotalXml(String? xmlContenido) {
    if (xmlContenido == null || xmlContenido.trim().isEmpty) {
      return null;
    }

    try {
      final documento = xml.XmlDocument.parse(xmlContenido);

      final importes = documento.findAllElements('MontoTotal').toList();

      if (importes.isEmpty) return null;

      return double.tryParse(importes.last.innerText.trim());
    } catch (_) {
      return null;
    }
  }

  String _razonModificacion(String codigo) {
    switch (codigo) {
      case '1':
        return 'Anulacion total del comprobante';
      case '2':
        return 'Correccion de texto';
      case '3':
        return 'Correccion de montos / devolucion';
      case '4':
        return 'Reemplazo NCF de contingencia';
      case '5':
        return 'Referencia a Factura de Consumo';
      default:
        return 'Ajuste del comprobante';
    }
  }
}
