class ImpuestoEntity {
  const ImpuestoEntity({
    this.id,
    required this.nombre,
    required this.porcentaje,
    required this.tipo,
    required this.esExento,
    this.activo = true,
    this.descripcion = '',
  });
  final int? id;
  final String nombre;
  final double porcentaje;
  final String
  tipo; // e.g., 'ITBIS', 'Selectivo al Consumo', 'Propina Legal', 'Exento'
  final bool esExento;
  final bool activo;
  final String descripcion;

  ImpuestoEntity copyWith({
    int? id,
    String? nombre,
    double? porcentaje,
    String? tipo,
    bool? esExento,
    bool? activo,
    String? descripcion,
  }) {
    return ImpuestoEntity(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      porcentaje: porcentaje ?? this.porcentaje,
      tipo: tipo ?? this.tipo,
      esExento: esExento ?? this.esExento,
      activo: activo ?? this.activo,
      descripcion: descripcion ?? this.descripcion,
    );
  }
}
