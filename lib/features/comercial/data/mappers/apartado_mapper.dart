import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/apartado.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

class ApartadoDataMapper {
  static Apartado toDomain(ApartadoData data, List<DetalleVenta> productos) {
    return Apartado(
      id: data.id,
      numero: 'APT-${data.id}',
      clienteId: data.clienteId,
      productos: productos,
      montoTotal: data.montoTotal,
      montoAbonado: data.montoAbonado,
      saldoPendiente: data.saldoPendiente,
      fechaApartado: data.fechaReserva,
      fechaLimitePago: data.fechaLimite,
      estado: data.estado,
      createdAt: null,
    );
  }

  static ApartadosTableCompanion toCompanion(Apartado entidad) {
    return ApartadosTableCompanion(
      clienteId: Value(entidad.clienteId),
      fechaReserva: Value(entidad.fechaApartado),
      fechaLimite: Value(entidad.fechaLimitePago ?? entidad.fechaApartado.add(const Duration(days: 30))),
      montoTotal: Value(entidad.montoTotal),
      montoAbonado: Value(entidad.montoAbonado),
      saldoPendiente: Value(entidad.saldoPendiente),
      estado: Value(entidad.estado),
    );
  }

  static ApartadosDetalleTableCompanion detalleToCompanion(DetalleVenta detalle, int apartadoId) {
    return ApartadosDetalleTableCompanion(
      apartadoId: Value(apartadoId),
      productoId: Value(detalle.productoId),
      cantidad: Value(detalle.cantidad),
      precioUnitario: Value(detalle.precioUnitario),
      subtotal: Value(detalle.subtotalLinea),
    );
  }
}

extension ApartadoDataEntityMapper on ApartadoData {
  Apartado toEntity({
    required String numero,
    List<DetalleVenta> productos = const [],
  }) {
    return Apartado(
      id: id,
      numero: numero,
      clienteId: clienteId,
      productos: productos,
      montoTotal: montoTotal,
      montoAbonado: montoAbonado,
      saldoPendiente: saldoPendiente,
      fechaApartado: fechaReserva,
      fechaLimitePago: fechaLimite,
      estado: estado,
      createdAt: null,
    );
  }
}

extension ApartadoDetalleDataEntityMapper on ApartadoDetalleData {
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
