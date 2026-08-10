import 'package:equatable/equatable.dart';

class Impuesto extends Equatable {
  const Impuesto({
    this.id,
    required this.nombre,
    required this.porcentaje,
    required this.tipo,
    required this.esExento,
    required this.descripcion,
    required this.activo,
  });

  final int? id;
  final String nombre;
  final double porcentaje;
  final String tipo;
  final bool esExento;
  final String descripcion;
  final bool activo;

  // ✅ Método copyWith AGREGADO COMPLETO, coincide cada campo existente
  Impuesto copyWith({
    int? id,
    String? nombre,
    double? porcentaje,
    String? tipo,
    bool? esExento,
    String? descripcion,
    bool? activo,
  }) {
    return Impuesto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      porcentaje: porcentaje ?? this.porcentaje,
      tipo: tipo ?? this.tipo,
      esExento: esExento ?? this.esExento,
      descripcion: descripcion ?? this.descripcion,
      activo: activo ?? this.activo,
    );
  }

  // ✅ Lista props COMPLETADA Y CERRADA, incluye TODOS campos
  @override
  List<Object?> get props => [
        id,
        nombre,
        porcentaje,
        tipo,
        esExento,
        descripcion,
        activo,
      ];
}
