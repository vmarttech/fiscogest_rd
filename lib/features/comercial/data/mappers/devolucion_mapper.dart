import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/devolucion.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

class DevolucionDataMapper {
  static Devolucion toDomain(DevolucionData data, DevolucionDetalleData? detalle) {
    return Devolucion(
      id: data.id,
      numero: 'DEV-${data.id}',
      ventaId: data.ventaId,
      productoId: detalle?.productoId ?? 0,
      cantidadDevuelta: detalle?.cantidad ?? 0,
      montoReembolsado: data.montoDevuelto,
      motivo: data.motivo,
      fecha: data.fecha,
      estado: data.estado,
      createdAt: null,
    );
  }

  static DevolucionesTableCompanion toCompanion(Devolucion entidad) {
    return DevolucionesTableCompanion(
      ventaId: Value(entidad.ventaId),
      fecha: Value(entidad.fecha),
      motivo: Value(entidad.motivo),
      tipo: const Value('Total'),
      montoDevuelto: Value(entidad.montoReembolsado),
      estado: Value(entidad.estado),
      afectaInventario: const Value(true),
      afectaCaja: const Value(true),
    );
  }

  static DevolucionesDetalleTableCompanion detalleToCompanion(Devolucion entidad, int devolucionId) {
    return DevolucionesDetalleTableCompanion(
      devolucionId: Value(devolucionId),
      productoId: Value(entidad.productoId),
      cantidad: Value(entidad.cantidadDevuelta),
      precioUnitario: Value(entidad.montoReembolsado / entidad.cantidadDevuelta),
      subtotal: Value(entidad.montoReembolsado),
      motivoLinea: Value(entidad.motivo),
    );
  }
}

extension DevolucionDataEntityMapper on DevolucionData {
  Devolucion toEntity({
    required String numero,
    List<DetalleVenta> productos = const [],
  }) {
    final cantidadDev = productos.isNotEmpty
        ? productos.fold<double>(0, (sum, d) => sum + d.cantidad)
        : 0.0;
    final primerProducto = productos.isNotEmpty ? productos.first.productoId : 0;

    return Devolucion(
      id: id,
      numero: numero,
      ventaId: ventaId,
      productoId: primerProducto,
      cantidadDevuelta: cantidadDev,
      montoReembolsado: montoDevuelto,
      motivo: motivo,
      fecha: fecha,
      estado: estado,
      createdAt: null,
    );
  }
}

extension DevolucionDetalleDataEntityMapper on DevolucionDetalleData {
  DetalleVenta toEntity({String nombreProducto = ''}) {
    return DetalleVenta(
      productoId: productoId,
      nombreProducto: nombreProducto,
      cantidad: cantidad,
      precioUnitario: precioUnitario,
      subtotalLinea: subtotal,
    );
  }
}
