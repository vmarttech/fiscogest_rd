import 'package:equatable/equatable.dart';

class AjusteInventario extends Equatable {

  const AjusteInventario({
    this.id,
    required this.codigoBusqueda,
    required this.idProducto,
    required this.cantidad,
    required this.tipoAjuste,
    required this.motivo,
    required this.usuarioId,
    required this.fechaCreacion,
  });
  final int? id;
  final String codigoBusqueda;
  final int idProducto;
  final double cantidad;
  final String tipoAjuste;
  final String motivo;
  final int usuarioId;
  final DateTime fechaCreacion;

  AjusteInventario copyWith({
    int? id,
    String? codigoBusqueda,
    int? idProducto,
    double? cantidad,
    String? tipoAjuste,
    String? motivo,
    int? usuarioId,
    DateTime? fechaCreacion,
  }) {
    return AjusteInventario(
      id: id ?? this.id,
      codigoBusqueda: codigoBusqueda ?? this.codigoBusqueda,
      idProducto: idProducto ?? this.idProducto,
      cantidad: cantidad ?? this.cantidad,
      tipoAjuste: tipoAjuste ?? this.tipoAjuste,
      motivo: motivo ?? this.motivo,
      usuarioId: usuarioId ?? this.usuarioId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  @override
  List<Object?> get props => [
        id,
        codigoBusqueda,
        idProducto,
        cantidad,
        tipoAjuste,
        motivo,
        usuarioId,
        fechaCreacion,
      ];
}
