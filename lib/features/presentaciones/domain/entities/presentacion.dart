import 'package:equatable/equatable.dart';

class Presentacion extends Equatable {
  const Presentacion({
    this.id,
    required this.nombre,
    required this.abreviatura,
    required this.activo,
  });

  final int? id;
  final String nombre;
  final String abreviatura;
  final bool activo;

  // ✅ Método copyWith AGREGADO COMPLETO, coincide cada campo existente
  Presentacion copyWith({
    int? id,
    String? nombre,
    String? abreviatura,
    bool? activo,
  }) {
    return Presentacion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      abreviatura: abreviatura ?? this.abreviatura,
      activo: activo ?? this.activo,
    );
  }

  // ✅ Lista props ya completa y correcta → MANTENIDA INTACTA
  @override
  List<Object?> get props => [
        id,
        nombre,
        abreviatura,
        activo,
      ];
}
