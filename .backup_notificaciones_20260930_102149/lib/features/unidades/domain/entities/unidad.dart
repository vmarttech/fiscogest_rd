class Unidad {
  Unidad({
    this.id,
    required this.nombre,
    required this.abreviatura,
    this.activo = true,
  });
  final int? id;
  final String nombre;
  final String abreviatura;
  final bool activo;

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
}
