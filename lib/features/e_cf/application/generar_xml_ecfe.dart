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
    try {
      final doc = await repo.obtenerPorId(documentoId);
      if (doc == null) {
        return const GenerarXmlResultado(
          ok: false,
          errores: ['Documento e-CF no encontrado'],
        );
      }
      if (doc.tipoEcf != TipoEcf.facturaCreditoFiscal &&
          doc.tipoEcf != TipoEcf.facturaConsumo &&
          doc.tipoEcf != TipoEcf.notaCredito) {
        return GenerarXmlResultado(
          ok: false,
          errores: [
            'Tipo ${doc.tipoEcf.codigo} aún no soportado en generación XML '
            '(soportados: 31, 32, 34)',
          ],
        );
      }
      if (detalles.isEmpty) {
        return const GenerarXmlResultado(
          ok: false,
          errores: ['La venta no tiene líneas de detalle'],
        );
      }

      if (doc.tipoEcf == TipoEcf.notaCredito) {
        final ref = (doc.encfReferencia ?? '').trim();
        if (ref.isEmpty) {
          return const GenerarXmlResultado(
            ok: false,
            errores: [
              'Nota de crédito (34): indica el e-NCF de referencia '
              '(comprobante modificado) en el detalle e-CF',
            ],
          );
        }
      }
      // Reutilizar e-NCF formal si el documento ya lo tiene (reintento / regenerar).
      late final String encfAsignado;
      late final DateTime? vencSeq;
      if (EcfeSecuenciaService.esEncfFormal(doc.encf)) {
        encfAsignado = doc.encf!.trim().toUpperCase();
        vencSeq = null;
      } else {
        final seq = await secuencias.siguiente(doc.tipoEcf);
        encfAsignado = seq.encf;
        vencSeq = seq.vencimiento;
      }
      final fmt = DateFormat('dd-MM-yyyy');
      final fechaEmision = fmt.format(venta.fecha);
      final fechaVenc = vencSeq != null
          ? fmt.format(vencSeq)
          : fmt.format(DateTime(DateTime.now().year + 1, 12, 31));

      final items = <EcfePayloadItem>[];
      // Líneas en 0 y la venta sí cobró ITBIS: documento viejo, una sola tasa.
      final usarTasaDocumento = detalles.every((d) => d.tasaImpuesto <= 0.0001) &&
          venta.itbis > 0.009;
      var gravado18 = 0.0;
      var itbis18 = 0.0;
      var gravado16 = 0.0;
      var itbis16 = 0.0;
      var exento = 0.0;
      for (var i = 0; i < detalles.length; i++) {
        final d = detalles[i];
        final monto = d.subtotalLinea ?? d.subtotal;
        final tasaLinea = usarTasaDocumento ? tasaItbis : d.tasaImpuesto;
        final pct = tasaLinea > 1.5 ? tasaLinea : tasaLinea * 100.0;
        final indFact =
            pct >= 17.5 ? '1' : (pct >= 15.5 ? '2' : '4');
        final fr = pct / 100.0;
        if (indFact == '1') {
          gravado18 += monto;
          itbis18 += monto * fr;
        } else if (indFact == '2') {
          gravado16 += monto;
          itbis16 += monto * fr;
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

      final tipoPago = venta.formaPago.toLowerCase().contains('cred')
          ? '2'
          : '1';

      final payload = EcfePayload(
        tipoEcfCodigo: doc.tipoEcf.codigo,
        encf: encfAsignado,
        encfReferencia: doc.encfReferencia,
        fechaVencimientoSecuencia: fechaVenc,
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
        rncComprador: rncCliente.trim().isEmpty ? null : rncCliente.trim(),
        razonSocialComprador: nombreCliente.trim().isEmpty
            ? (venta.nombreCliente ?? 'CONSUMIDOR FINAL')
            : nombreCliente.trim(),
        direccionComprador: venta.clienteDireccion,
        montoGravadoTotal: gravado18 + gravado16,
        totalItbis: itbis18 + itbis16,
        montoTotal: venta.montoTotal,
        tasaItbis: gravado18 > 0 ? 18 : (gravado16 > 0 ? 16 : 0),
        montoGravadoI1: gravado18,
        totalItbis1: itbis18,
        montoGravadoI2: gravado16,
        totalItbis2: itbis16,
        montoExento: exento,
        bandasItbis: true,
        items: items,
        montoPago: venta.montoTotal,
      );

      final xml = builder.construirDesdePayload(payload);
      final val = await EcfeXsdValidatorImpl(
        rutaXsd: rutaXsd,
        exigirXsd: exigirXsd,
      ).validar(xml);

      if (!val.ok) {
        await repo.guardarXml(
          id: documentoId,
          xmlSinFirma: xml,
          encf: encfAsignado,
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

      await repo.guardarXml(
        id: documentoId,
        xmlSinFirma: xml,
        encf: encfAsignado,
        estado: EstadoEcfInterno.xmlListo,
        ultimoError: null,
      );
      await repo.registrarEvento(
        documentoId: documentoId,
        paso: 'generar_xml',
        ok: true,
        detalle: 'XML generado $encfAsignado',
      );
      await repo.registrarEvento(
        documentoId: documentoId,
        paso: 'validar_estructura',
        ok: true,
        detalle: 'Validación estructural OK',
      );

      return GenerarXmlResultado(ok: true, xml: xml, encf: encfAsignado);
    } catch (e) {
      try {
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
      } catch (_) {}
      return GenerarXmlResultado(ok: false, errores: ['$e']);
    }
  }
}
