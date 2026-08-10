import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/ajuste_inventario.dart';

class AjusteInventarioModel extends AjusteInventario {
  const AjusteInventarioModel({
    super.id,
    required super.codigoBusqueda,
    required super.idProducto,
    required super.cantidad,
    required super.tipoAjuste,
    required super.motivo,
    required super.usuarioId,
    required super.fechaCreacion,
  });

  factory AjusteInventarioModel.fromJson(Map<String, dynamic> json) => AjusteInventarioModel(
    id: json['id'] as int?,
    codigoBusqueda: json['codigoBusqueda'] as String? ?? '',
    idProducto: json['idProducto'] as int,
    cantidad: (json['cantidad'] as num).toDouble(),
    tipoAjuste: json['tipoAjuste'] as String,
    motivo: json['motivo'] as String,
    usuarioId: json['usuarioId'] as int,
    fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'codigoBusqueda': codigoBusqueda,
    'idProducto': idProducto,
    'cantidad': cantidad,
    'tipoAjuste': tipoAjuste,
    'motivo': motivo,
    'usuarioId': usuarioId,
    'fechaCreacion': fechaCreacion.toIso8601String(),
  };
}
