import 'package:fiscogest_rd/features/e_cf/data/repositories/ecfe_repository.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/estado_ecf_interno.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/tipo_ecf.dart';
import 'package:fiscogest_rd/features/e_cf/domain/services/ecfe_negocio_validator.dart';
import 'package:fiscogest_rd/features/e_cf/domain/services/rfce_rules.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

/// Resultado del intento de encolado (nunca debe romper ventas).
class EcfeEncolarResultado {
  const EcfeEncolarResultado({
    required this.encolado,
    this.documentoId,
    this.omitidoPor,
    this.erroresValidacion = const [],
  });

  final bool encolado;
  final int? documentoId;
  final String? omitidoPor;
  final List<String> erroresValidacion;
}

/// Encola un e-CF desde una venta ya facturada localmente.
/// Si el módulo está off o falla validación → no lanza; solo reporta.
class EncolarEcfeDesdeVenta {
  EncolarEcfeDesdeVenta({required this.repo, required this.validator});

  final EcfeRepository repo;
  final EcfeNegocioValidator validator;

  Future<EcfeEncolarResultado> call({
    required Venta venta,
    required String tipoNcf,
    required String rncCliente,
    required String nombreCliente,
  }) async {
    try {
      final cfg = await repo.obtenerConfig();
      if (!cfg.habilitado || !cfg.ambiente.permiteEnvio) {
        return const EcfeEncolarResultado(
          encolado: false,
          omitidoPor: 'Módulo e-CF deshabilitado o ambiente sin envío',
        );
      }

      // Evitar duplicados por venta
      final tipo = TipoEcf.desdeTipoNcfLocal(tipoNcf);
      if (tipo == null) {
        return EcfeEncolarResultado(
          encolado: false,
          omitidoPor: 'Tipo NCF $tipoNcf sin mapeo e-CF',
        );
      }

      final previos = await repo.listarPorVentaId(venta.id!);
      final esNota = tipo == TipoEcf.notaCredito || tipo == TipoEcf.notaDebito;
      if (!esNota && previos.isNotEmpty) {
        return EcfeEncolarResultado(
          encolado: false,
          documentoId: previos.first.id,
          omitidoPor: 'Ya existe documento e-CF para esta venta',
        );
      }
      if (esNota && previos.any((previo) => previo.tipoEcf == tipo)) {
        final ya = previos.firstWhere((previo) => previo.tipoEcf == tipo);
        return EcfeEncolarResultado(
          encolado: false,
          documentoId: ya.id,
          omitidoPor: 'Ya existe esta nota electronica para la venta',
        );
      }

      var encfOrigen = '';
      for (final previo in previos) {
        final esFactura =
            previo.tipoEcf != TipoEcf.notaCredito &&
            previo.tipoEcf != TipoEcf.notaDebito;
        if (esFactura && encfOrigen.isEmpty) {
          encfOrigen = (previo.encf ?? '').trim();
        }
      }

      var rncNota = rncCliente.replaceAll(RegExp(r'\D'), '');
      if (rncNota.isEmpty) {
        for (final previo in previos) {
          final guardado = (previo.rncReceptor ?? '').trim();
          if (guardado.isNotEmpty) {
            rncNota = guardado;
            break;
          }
        }
      }

      final ncf = (venta.numeroFactura ?? '').trim();
      final validacion = validator.validarParaEncolar(
        config: cfg,
        tipoEcf: tipo,
        rncReceptor: rncNota,
        nombreReceptor: nombreCliente,
        subtotal: venta.montoSubtotal,
        itbis: venta.itbis,
        total: venta.montoTotal,
        ncfLocal: ncf,
      );
      final notaErrores = <String>[...validacion.errores];
      if (esNota && encfOrigen.isEmpty) {
        notaErrores.add(
          'La factura todavía no tiene e-NCF. El e-CF de la nota no se envía hasta que la factura electrónica lo tenga.',
        );
      }
      if (esNota && rncNota.isEmpty) {
        for (final previo in previos) {
          final exigeRnc =
              previo.tipoEcf == TipoEcf.facturaCreditoFiscal ||
              previo.tipoEcf == TipoEcf.regimenesEspeciales;
          if (exigeRnc) {
            notaErrores.add(
              'Esa factura es crédito fiscal o regímenes especiales y no tiene RNC guardado. No se envía el e-CF de la nota.',
            );
            break;
          }
        }
      }
      if (esNota && encfOrigen.isNotEmpty) {
        for (final previo in previos) {
          final mismo =
              (previo.encf ?? '').trim().toUpperCase() ==
              encfOrigen.toUpperCase();
          if (mismo && previo.estado == EstadoEcfInterno.rechazado) {
            notaErrores.add(
              'La factura electrónica fue rechazada. No se envía la nota contra un e-NCF rechazado.',
            );
            break;
          }
        }
      }

      final notaOk =
          validacion.ok && notaErrores.length == validacion.errores.length;

      final estado = notaOk
          ? EstadoEcfInterno.borrador
          : EstadoEcfInterno.validacionFallida;

      final id = await repo.insertarDocumento(
        ventaId: venta.id!,
        tipoEcf: tipo,
        estado: estado,
        ncfLocal: ncf,
        rncReceptor: rncNota.isEmpty ? null : rncNota,
        notaFiscalJson: notaFiscalJsonDe(venta),
        encfReferencia: esNota && encfOrigen.isNotEmpty ? encfOrigen : null,
        ultimoError: notaOk ? null : notaErrores.join(' · '),
      );

      await repo.registrarEvento(
        documentoId: id,
        paso: notaOk ? 'encolar' : 'validacion_negocio',
        ok: notaOk,
        detalle: notaOk
            ? 'Encolado desde venta #${venta.id}'
            : notaErrores.join(' · '),
      );
      if (notaOk &&
          RfceRules.esCandidatoRfce(tipo: tipo, total: venta.montoTotal)) {
        await repo.registrarEvento(
          documentoId: id,
          paso: 'rfce',
          ok: true,
          detalle: 'Candidato RFCE (total < RD\$250,000)',
        );
      }

      return EcfeEncolarResultado(
        encolado: true,
        documentoId: id,
        erroresValidacion: notaErrores,
      );
    } catch (e) {
      // Aislamiento total: no propagar a ventas
      return EcfeEncolarResultado(
        encolado: false,
        omitidoPor: 'Error interno e-CF: $e',
      );
    }
  }
}

String notaFiscalJsonDe(Venta venta) {
  final lineas = <String>[];
  for (final d in venta.detalles) {
    final monto = (d.subtotalLinea ?? d.subtotal).toStringAsFixed(2);
    final nombre = (d.nombreProducto ?? '')
        .replaceAll(RegExp(r'["\\$]'), '')
        .replaceAll('\n', ' ');
    lineas.add(
      '{"nombre":"$nombre","cantidad":${d.cantidad},"precio":${d.precioUnitario},"monto":$monto,"tasa":${d.tasaImpuesto}}',
    );
  }
  return '{"montoTotal":${venta.montoTotal.toStringAsFixed(2)},'
      '"itbis":${venta.itbis.toStringAsFixed(2)},'
      '"lineas":[${lineas.join(',')}]}';
}
