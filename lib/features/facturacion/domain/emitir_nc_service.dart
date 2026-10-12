import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/facturacion/data/dao/notas_credito_dao.dart';
import 'package:fiscogest_rd/features/facturacion/data/dao/secuencias_ncf_dao.dart';
import 'package:fiscogest_rd/features/ventas/data/repositories/ventas_repository_impl.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/i_venta_inventario_service.dart';
import 'package:fiscogest_rd/features/facturacion/domain/emitir_factura_service.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';

class EmitirNcService {
  EmitirNcService({
    required this.ventasRepo,
    required this.secuenciasDao,
    required this.notasDao,
    required this.inventarioService,
    required this.cuentasCobrarDao,
    this.onPostEmision,
  });

  final VentasRepositoryImpl ventasRepo;
  final SecuenciasNcfDao secuenciasDao;
  final NotasCreditoDao notasDao;
  final IVentaInventarioService inventarioService;
  final CuentasCobrarDao cuentasCobrarDao;
  final EcfePostEmisionHook? onPostEmision;

  Future<EmitirNcResultado> emitir({
    required int facturaVentaId,
    required String motivo,
    Map<int, double> cantidades = const <int, double>{},
  }) async {
    final venta = await ventasRepo.obtenerVentaPorId(facturaVentaId);
    if (venta == null) {
      throw StateError('Factura no encontrada');
    }
    final ncfOrigen = (venta.numeroFactura ?? '').trim();
    if (ncfOrigen.isEmpty) {
      throw StateError('El documento no tiene NCF de factura');
    }
    if (ncfOrigen.startsWith('B04')) {
      throw StateError('No se puede emitir NC sobre otra NC');
    }
    if (motivo.trim().isEmpty) {
      throw StateError('Indique el motivo de la nota de crédito');
    }

    // Idempotencia: una NC completa por factura origen
    final existentes = await notasDao.listar();
    final ya = existentes.any(
      (n) =>
          n.ncfFacturaOrigen == ncfOrigen || n.ventaIdOrigen == facturaVentaId,
    );
    if (ya) {
      throw StateError(
        'Ya existe una nota de crédito para esta factura ($ncfOrigen)',
      );
    }

    // Detalle completo para stock
    final ventaFull =
        await ventasRepo.obtenerVentaPorId(facturaVentaId) ?? venta;
    if (ventaFull.detalles.isEmpty) {
      throw StateError(
        'La factura no tiene líneas de detalle; no se puede revertir inventario',
      );
    }

    final ventaEcfe = _ventaDevolucion(ventaFull, cantidades);
    final ncfNc = await secuenciasDao.siguienteNcf('B04');

    // 1) Devolver stock + kardex entrada
    await inventarioService.aplicarEntradaInventarioPorNc(
      ventaEcfe,
      ncfNc: ncfNc,
    );

    // 2) Anular CxC si existe (crédito)
    if (_cubreTodaLaFactura(ventaFull, cantidades)) {
      await cuentasCobrarDao.anularCuentaPorNotaCredito(
        facturaVentaId,
        referencia: ncfNc,
      );
    }

    // 3) Registrar NC
    await notasDao.insertar(
      NotasCreditoTableCompanion.insert(
        ncf: ncfNc,
        ncfFacturaOrigen: ncfOrigen,
        ventaIdOrigen: facturaVentaId,
        numeroCotizacion: Value(venta.numeroCotizacion),
        nombreCliente: Value(venta.nombreCliente),
        monto: Value(ventaEcfe.montoTotal),
        motivo: Value(motivo.trim()),
      ),
    );

    // Hook e-CF (B04→E34), aislado
    String? avisoEcfe;
    final hook = onPostEmision;
    if (hook != null) {
      try {
        await hook(venta: ventaEcfe, tipoNcf: 'B04', rncCliente: '');
      } catch (e) {
        avisoEcfe =
            'La nota quedo registrada, pero el e-CF 34 no se genero: $e';
      }
    }
    return EmitirNcResultado(
      ncfNc: ncfNc,
      ncfFacturaOrigen: ncfOrigen,
      ventaId: facturaVentaId,
      numeroCotizacion: venta.numeroCotizacion,
      nombreCliente: venta.nombreCliente,
      montoTotal: ventaEcfe.montoTotal,
      motivo: motivo.trim(),
      inventarioRevertido: true,
      avisoEcfe: avisoEcfe,
      cxcAnulada: true,
    );
  }
}

bool _cubreTodaLaFactura(Venta venta, Map<int, double> cantidades) {
  if (cantidades.isEmpty) return true;
  for (var i = 0; i < venta.detalles.length; i++) {
    if (((cantidades[i] ?? 0) - venta.detalles[i].cantidad.toDouble()).abs() >
        0.001) {
      return false;
    }
  }
  return true;
}

DetalleVenta _detalleDevuelto(DetalleVenta d, double q) {
  final factor = d.cantidad.toDouble() == 0 ? 0.0 : q / d.cantidad.toDouble();
  final sub = (d.subtotalLinea ?? d.subtotal) * factor;
  return d.copyWith(cantidad: q.round(), subtotal: sub, subtotalLinea: sub);
}

Venta _ventaDevolucion(Venta venta, Map<int, double> cantidades) {
  if (_cubreTodaLaFactura(venta, cantidades)) return venta;
  if (venta.esCredito) {
    throw StateError(
      'En una venta a credito la devolucion tiene que ser de la factura completa.',
    );
  }
  final lineas = <DetalleVenta>[];
  var sub = 0.0;
  var itbis = 0.0;
  for (var i = 0; i < venta.detalles.length; i++) {
    final q = cantidades[i] ?? 0;
    if (q <= 0) continue;
    final d = venta.detalles[i];
    if (q > d.cantidad.toDouble() + 0.001) {
      throw StateError('La cantidad a devolver supera lo vendido');
    }
    final factor = d.cantidad.toDouble() == 0 ? 0.0 : q / d.cantidad.toDouble();
    final linea = (d.subtotalLinea ?? d.subtotal) * factor;
    final tasaRaw = (d.tasaImpuesto).toDouble();
    final tasa = tasaRaw > 1 ? tasaRaw / 100 : tasaRaw;
    sub += linea;
    itbis += linea * tasa;
    lineas.add(_detalleDevuelto(d, q));
  }
  if (lineas.isEmpty) {
    throw StateError('Indique la cantidad a devolver');
  }
  final base = venta.montoSubtotal <= 0 ? 0.0 : sub / venta.montoSubtotal;
  final desc = venta.montoDescuento * base;
  final total = sub - desc + itbis;
  if (total <= 0) {
    throw StateError('El monto a devolver debe ser mayor que cero');
  }
  return venta.copyWith(
    detalles: lineas,
    montoSubtotal: sub,
    itbis: itbis,
    montoTotal: total,
    montoDescuento: desc,
  );
}

class EmitirNcResultado {
  EmitirNcResultado({
    required this.ncfNc,
    required this.ncfFacturaOrigen,
    required this.ventaId,
    required this.numeroCotizacion,
    this.nombreCliente,
    required this.montoTotal,
    required this.motivo,
    this.inventarioRevertido = false,
    this.cxcAnulada = false,
    this.avisoEcfe,
  });

  final String ncfNc;
  final String ncfFacturaOrigen;
  final int ventaId;
  final String numeroCotizacion;
  final String? nombreCliente;
  final double montoTotal;
  final String motivo;
  final bool inventarioRevertido;
  final bool cxcAnulada;
  final String? avisoEcfe;
}
