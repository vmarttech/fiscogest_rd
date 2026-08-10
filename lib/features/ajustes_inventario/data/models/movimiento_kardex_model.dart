import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/movimiento_kardex.dart';

class MovimientoKardexModel extends MovimientoKardex {
  const MovimientoKardexModel({
    super.id,
    required super.idProducto,
    required super.tipoMovimiento,
    required super.cantidad,
    required super.saldoActual,
    super.referenciaId,
    required super.motivo,
    required super.usuarioId,
    required super.fechaMovimiento,
  });

  factory MovimientoKardexModel.fromJson(Map<String, dynamic> json) => MovimientoKardexModel(
    id: json['id'] as int?,
    idProducto: json['idProducto'] as int,
    tipoMovimiento: json['tipoMovimiento'] as String,
    cantidad: (json['cantidad'] as num).toDouble(),
    saldoActual: (json['saldoActual'] as num).toDouble(),
    referenciaId: json['referenciaId'] as int?,
    motivo: json['motivo'] as String,
    usuarioId: json['usuarioId'] as int,
    fechaMovimiento: DateTime.parse(json['fechaMovimiento'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'idProducto': idProducto,
    'tipoMovimiento': tipoMovimiento,
    'cantidad': cantidad,
    'saldoActual': saldoActual,
    'referenciaId': referenciaId,
    'motivo': motivo,
    'usuarioId': usuarioId,
    'fechaMovimiento': fechaMovimiento.toIso8601String(),
  };
}
