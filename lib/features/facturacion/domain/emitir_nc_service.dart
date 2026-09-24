import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/facturacion/data/dao/notas_credito_dao.dart';
import 'package:fiscogest_rd/features/facturacion/data/dao/secuencias_ncf_dao.dart';
import 'package:fiscogest_rd/features/ventas/data/repositories/ventas_repository_impl.dart';

class EmitirNcService {
  EmitirNcService({
    required this.ventasRepo,
    required this.secuenciasDao,
    required this.notasDao,
  });

  final VentasRepositoryImpl ventasRepo;
  final SecuenciasNcfDao secuenciasDao;
  final NotasCreditoDao notasDao;

  Future<EmitirNcResultado> emitir({
    required int facturaVentaId,
    required String motivo,
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

    final ncfNc = await secuenciasDao.siguienteNcf('B04');
    await notasDao.insertar(
      NotasCreditoTableCompanion.insert(
        ncf: ncfNc,
        ncfFacturaOrigen: ncfOrigen,
        ventaIdOrigen: facturaVentaId,
        numeroCotizacion: Value(venta.numeroCotizacion),
        nombreCliente: Value(venta.nombreCliente),
        monto: Value(venta.montoTotal),
        motivo: Value(motivo.trim()),
      ),
    );

    return EmitirNcResultado(
      ncfNc: ncfNc,
      ncfFacturaOrigen: ncfOrigen,
      ventaId: facturaVentaId,
      numeroCotizacion: venta.numeroCotizacion,
      nombreCliente: venta.nombreCliente,
      montoTotal: venta.montoTotal,
      motivo: motivo.trim(),
    );
  }
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
  });

  final String ncfNc;
  final String ncfFacturaOrigen;
  final int ventaId;
  final String numeroCotizacion;
  final String? nombreCliente;
  final double montoTotal;
  final String motivo;
}
