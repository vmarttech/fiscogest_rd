class Categoria {
  final int? id;
  final String nombre;
  final String descripcion;
  final bool activo;

  Categoria({
    this.id,
    required this.nombre,
    this.descripcion = '',
    this.activo = true,
  });

  Categoria copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    bool? activo,
  }) {
    return Categoria(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      activo: activo ?? this.activo,
    );
  }
}
