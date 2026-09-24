import 'package:fiscogest_rd/features/facturacion/data/dao/secuencias_ncf_dao.dart';
import 'package:fiscogest_rd/features/ventas/data/repositories/ventas_repository_impl.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';

/// Emite nota de crédito (B04) referenciando una factura existente.
class EmitirNcService {
  EmitirNcService({
    required this.ventasRepo,
    required this.secuenciasDao,
  });

  final VentasRepositoryImpl ventasRepo;
  final SecuenciasNcfDao secuenciasDao;

  /// Valida factura origen y reserva B04.
  /// Persistencia mínima: guarda NCF de NC en campo dedicado si existe;
  /// si no, retorna el NCF para que la UI lo muestre (historial NC en F2).
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
    if (venta.estadoDocumento != EstadoDocumento.facturado &&
        ncfOrigen.isEmpty) {
      throw StateError('Solo se emite NC sobre facturas emitidas');
    }
    if (motivo.trim().isEmpty) {
      throw StateError('Indique el motivo de la nota de crédito');
    }

    final ncfNc = await secuenciasDao.siguienteNcf('B04');

    // Marcamos referencia en numeroFactura solo si aún no hay NC guardada;
    // no pisamos el NCF de la factura. La NC se registra como texto de
    // seguimiento vía motivo + ncfNc (impreso/historial).
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
