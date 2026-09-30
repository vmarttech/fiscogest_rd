class Presentacion {
  Presentacion({
    this.id,
    required this.nombre,
    required this.abreviatura,
    this.activo = true,
  });
  final int? id;
  final String nombre;
  final String abreviatura;
  final bool activo;

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
}
