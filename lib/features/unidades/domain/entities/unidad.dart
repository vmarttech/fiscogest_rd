import 'package:equatable/equatable.dart';

class Unidad extends Equatable {
  const Unidad({
    this.id,
    required this.nombre,
    required this.abreviatura,
    required this.activo,
  });

  final int? id;
  final String nombre;
  final String abreviatura;
  final bool activo;

  // ✅ Método copyWith completo, TODOS campos, nombres EXACTOS
  Unidad copyWith({
    int? id,
    String? nombre,
    String? abreviatura,
    bool? activo,
  }) {
    return Unidad(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      abreviatura: abreviatura ?? this.abreviatura,
      activo: activo ?? this.activo,
    );
  }

  // ✅ Propiedades para Equatable
  @override
  List<Object?> get props => [id, nombre, abreviatura, activo];
}
