import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/cotizacion.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

class CotizacionDataMapper {
  static Cotizacion toDomain(CotizacionData data, List<DetalleVenta> detalles) {
    return Cotizacion(
      id: data.id,
      numero: 'COT-${data.id}',
      clienteId: data.clienteId,
      fechaEmision: data.fechaEmision,
      fechaVencimiento: data.fechaVigencia,
      detalles: detalles,
      subtotal: data.montoSubtotal,
      itbis: data.itbis,
      total: data.montoTotal,
      convertidaAVenta: data.ventaConvertidaId != null,
      ventaId: data.ventaConvertidaId,
      createdAt: null,
    );
  }

  static CotizacionesTableCompanion toCompanion(Cotizacion entidad) {
    return CotizacionesTableCompanion(
      clienteId: Value(entidad.clienteId),
      fechaEmision: Value(entidad.fechaEmision),
      fechaVigencia: Value(entidad.fechaVencimiento),
      montoSubtotal: Value(entidad.subtotal),
      descuentoGlobal: const Value(0),
      itbis: Value(entidad.itbis),
      montoTotal: Value(entidad.total),
      estado: const Value('Pendiente'),
    );
  }

  static CotizacionesDetalleTableCompanion detalleToCompanion(DetalleVenta detalle, int cotizacionId) {
    return CotizacionesDetalleTableCompanion(
      cotizacionId: Value(cotizacionId),
      productoId: Value(detalle.productoId),
      cantidad: Value(detalle.cantidad),
      precioUnitario: Value(detalle.precioUnitario),
      descuentoLinea: Value(detalle.descuentoPorcentaje ?? 0),
      subtotal: Value(detalle.subtotalLinea),
    );
  }
}

extension CotizacionDataEntityMapper on CotizacionData {
  Cotizacion toEntity({
    required String numero,
    List<DetalleVenta> detalles = const [],
  }) {
    return Cotizacion(
      id: id,
      numero: numero,
      clienteId: clienteId,
      fechaEmision: fechaEmision,
      fechaVencimiento: fechaVigencia,
      detalles: detalles,
      subtotal: montoSubtotal,
      itbis: itbis,
      total: montoTotal,
      convertidaAVenta: ventaConvertidaId != null,
      ventaId: ventaConvertidaId,
      createdAt: null,
    );
  }
}

extension CotizacionDetalleDataEntityMapper on CotizacionDetalleData {
  DetalleVenta toEntity({String nombreProducto = ''}) {
    return DetalleVenta(
      productoId: productoId,
      nombreProducto: nombreProducto,
      cantidad: cantidad,
      precioUnitario: precioUnitario,
      descuentoPorcentaje: descuentoLinea > 0 ? descuentoLinea : null,
      subtotalLinea: subtotal,
    );
  }
}
