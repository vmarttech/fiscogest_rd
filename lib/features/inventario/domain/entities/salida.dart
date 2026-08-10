import 'package:equatable/equatable.dart';

class Salida extends Equatable {

  const Salida({
    this.id,
    required this.productoId,
    required this.cantidad,
    required this.motivo,
    required this.usuarioId,
    required this.fecha,
  });
  final int? id;
  final int productoId;
  final double cantidad;
  final String motivo;
  final int usuarioId;
  final DateTime fecha;

  @override
  List<Object?> get props => [
        id,
        productoId,
        cantidad,
        motivo,
        usuarioId,
        fecha,
      ];
}
