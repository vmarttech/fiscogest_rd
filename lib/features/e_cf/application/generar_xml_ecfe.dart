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
          doc.tipoEcf != TipoEcf.facturaConsumo) {
        return GenerarXmlResultado(
          ok: false,
          errores: ['Tipo ${doc.tipoEcf.codigo} no soportado en Fase 2'],
        );
      }
      if (detalles.isEmpty) {
        return const GenerarXmlResultado(
          ok: false,
          errores: ['La venta no tiene líneas de detalle'],
        );
      }

      final seq = await secuencias.siguiente(doc.tipoEcf);
      final fmt = DateFormat('dd-MM-yyyy');
      final fechaEmision = fmt.format(venta.fecha);
      final fechaVenc = seq.vencimiento != null
          ? fmt.format(seq.vencimiento!)
          : fmt.format(DateTime(DateTime.now().year + 1, 12, 31));

      final items = <EcfePayloadItem>[];
      for (var i = 0; i < detalles.length; i++) {
        final d = detalles[i];
        final monto = d.subtotalLinea ?? d.subtotal;
        final indFact =
            tasaItbis >= 17.5 ? '1' : (tasaItbis >= 15.5 ? '2' : '3');
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
        encf: seq.encf,
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
        montoGravadoTotal: venta.montoSubtotal,
        totalItbis: venta.itbis,
        montoTotal: venta.montoTotal,
        tasaItbis: tasaItbis,
        items: items,
        montoPago: venta.montoTotal,
      );

      final xml = builder.construirDesdePayload(payload);
      final val = await EcfeXsdValidatorImpl(rutaXsd: rutaXsd).validar(xml);

      if (!val.ok) {
        await repo.guardarXml(
          id: documentoId,
          xmlSinFirma: xml,
          encf: seq.encf,
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
          encf: seq.encf,
          errores: val.errores,
        );
      }

      await repo.guardarXml(
        id: documentoId,
        xmlSinFirma: xml,
        encf: seq.encf,
        estado: EstadoEcfInterno.xmlListo,
        ultimoError: null,
      );
      await repo.registrarEvento(
        documentoId: documentoId,
        paso: 'generar_xml',
        ok: true,
        detalle: 'XML generado ${seq.encf}',
      );
      await repo.registrarEvento(
        documentoId: documentoId,
        paso: 'validar_estructura',
        ok: true,
        detalle: 'Validación estructural OK',
      );

      return GenerarXmlResultado(ok: true, xml: xml, encf: seq.encf);
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
