import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

class VentaDataMapper {
  static Venta toDomain(VentaData data, List<DetalleVenta> detalles) {
    return Venta(
      id: data.id,
      numero: 'VTA-${data.id}',
      clienteId: data.clienteId,
      fecha: data.fecha,
      detalles: detalles,
      subtotal: data.montoSubtotal,
      itbis: data.itbis,
      total: data.montoTotal,
      tipoPago: data.formaPago,
      esCredito: false,
      cotizacionOrigenId: null,
      apartadoOrigenId: null,
      createdAt: data.fechaRegistro,
      updatedAt: null,
    );
  }

  static VentasTableCompanion toCompanion(Venta entidad, int usuarioId) {
    return VentasTableCompanion(
      clienteId: Value(entidad.clienteId),
      fecha: Value(entidad.fecha),
      montoSubtotal: Value(entidad.subtotal),
      descuentoGlobal: const Value(0),
      itbis: Value(entidad.itbis),
      montoTotal: Value(entidad.total),
      formaPago: Value(entidad.tipoPago),
      estado: const Value('Confirmada'),
      usuarioId: Value(usuarioId),
    );
  }

  static VentasDetalleTableCompanion detalleToCompanion(DetalleVenta detalle, int ventaId) {
    return VentasDetalleTableCompanion(
      ventaId: Value(ventaId),
      productoId: Value(detalle.productoId),
      cantidad: Value(detalle.cantidad),
      precioUnitario: Value(detalle.precioUnitario),
      descuentoLinea: Value(detalle.descuentoPorcentaje ?? 0),
      subtotal: Value(detalle.subtotalLinea),
      impuesto: Value(detalle.subtotalLinea * 0.18),
    );
  }

  static DetalleVenta detalleToDomain(VentaDetalleData data, String nombreProducto) {
    return DetalleVenta(
      productoId: data.productoId,
      nombreProducto: nombreProducto,
      cantidad: data.cantidad,
      precioUnitario: data.precioUnitario,
      descuentoPorcentaje: data.descuentoLinea > 0 ? data.descuentoLinea : null,
      montoDescuento: data.descuentoLinea > 0
          ? data.descuentoLinea * data.precioUnitario * data.cantidad / 100
          : null,
      subtotalLinea: data.subtotal,
    );
  }
}

extension VentaDataEntityMapper on VentaData {
  Venta toEntity({
    required String numero,
    required List<DetalleVenta> detalles,
    int? cotizacionOrigenId,
    int? apartadoOrigenId,
  }) {
    return Venta(
      id: id,
      numero: numero,
      clienteId: clienteId,
      fecha: fecha,
      detalles: detalles,
      subtotal: montoSubtotal,
      itbis: itbis,
      total: montoTotal,
      tipoPago: formaPago,
      esCredito: false,
      cotizacionOrigenId: cotizacionOrigenId,
      apartadoOrigenId: apartadoOrigenId,
      createdAt: fechaRegistro,
      updatedAt: null,
    );
  }
}

extension VentaDetalleDataEntityMapper on VentaDetalleData {
  DetalleVenta toEntity({String nombreProducto = ''}) {
    return DetalleVenta(
      productoId: productoId,
      nombreProducto: nombreProducto,
      cantidad: cantidad,
      precioUnitario: precioUnitario,
      descuentoPorcentaje: descuentoLinea > 0 ? descuentoLinea : null,
      montoDescuento: descuentoLinea > 0
          ? descuentoLinea * precioUnitario * cantidad / 100
          : null,
      subtotalLinea: subtotal,
    );
  }
}
