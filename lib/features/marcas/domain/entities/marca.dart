class Marca {
  final int? id;
  final String nombre;
  final String descripcion;
  final bool activo;

   Marca({
    this.id,
    required this.nombre,
    this.descripcion = '',
    this.activo = true,
  });

  Marca copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    bool? activo,
  }) {
    return Marca(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      activo: activo ?? this.activo,
    );
  }
}
