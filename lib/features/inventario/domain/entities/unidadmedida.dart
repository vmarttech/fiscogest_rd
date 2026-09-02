class UnidadMedida {
  const UnidadMedida({this.id, required this.nombre});
  final int? id;
  final String nombre;

  UnidadMedida copyWith({int? id, String? nombre}) {
    return UnidadMedida(id: id ?? this.id, nombre: nombre ?? this.nombre);
  }
}
