import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/movimiento_kardex.dart';

class MovimientoKardexModel {

  const MovimientoKardexModel({
    this.id,
    required this.idProducto,
    required this.tipoMovimiento,
    required this.cantidad,
    required this.saldoActual,
    this.referenciaId,
    required this.motivo,
    required this.usuarioId,
    required this.fechaMovimiento,
  });

  factory MovimientoKardexModel.fromEntity(MovimientoKardex entity) {
    return MovimientoKardexModel(
      id: entity.id,
      idProducto: entity.idProducto,
      tipoMovimiento: entity.tipoMovimiento,
      cantidad: entity.cantidad,
      saldoActual: entity.saldoActual,
      referenciaId: entity.referenciaId,
      motivo: entity.motivo,
      usuarioId: entity.usuarioId,
      fechaMovimiento: entity.fechaMovimiento,
    );
  }
  final int? id;
  final int idProducto;
  final String tipoMovimiento;
  final double cantidad;
  final double saldoActual;
  final int? referenciaId;
  final String motivo;
  final int usuarioId;
  final DateTime fechaMovimiento;

  MovimientoKardex toEntity() {
    return MovimientoKardex(
      id: id,
      idProducto: idProducto,
      tipoMovimiento: tipoMovimiento,
      cantidad: cantidad,
      saldoActual: saldoActual,
      referenciaId: referenciaId,
      motivo: motivo,
      usuarioId: usuarioId,
      fechaMovimiento: fechaMovimiento,
    );
  }
}
