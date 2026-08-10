import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/ajuste_inventario.dart';

class AjusteInventarioModel extends AjusteInventario {
  const AjusteInventarioModel({
    super.id,
    required super.idProducto,
    super.codigoBusqueda,
    required super.tipoAjuste,
    required super.cantidad,
    required super.motivo,
    required super.usuarioId,
    required super.fechaCreacion,
  });

  // Ejemplo desde mapa
  factory AjusteInventarioModel.fromMap(Map<String, dynamic> map) {
    return AjusteInventarioModel(
      id: map['id'] as int?,
      idProducto: map['idProducto'] as int,
      tipoAjuste: map['tipoAjuste'] as String,
      cantidad: map['cantidad'] as double,
      motivo: map['motivo'] as String,
      usuarioId: map['usuarioId'] as int,
      fechaCreacion: DateTime.parse(map['fechaCreacion'] as String),
    );
  }
}
