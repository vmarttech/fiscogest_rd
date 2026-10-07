class ImpuestoEntity {
  const ImpuestoEntity({
    this.id,
    this.codigo = '',
    required this.nombre,
    required this.porcentaje,
    required this.tipo,
    required this.esExento,
    this.esDefault = false,
    this.activo = true,
    this.descripcion = '',
  });

  final int? id;
  final String codigo;
  final String nombre;
  final double porcentaje;
  /// ITBIS | Exento | Adicional | Selectivo
  final String tipo;
  final bool esExento;
  final bool esDefault;
  final bool activo;
  final String descripcion;

  ImpuestoEntity copyWith({
    int? id,
    String? codigo,
    String? nombre,
    double? porcentaje,
    String? tipo,
    bool? esExento,
    bool? esDefault,
    bool? activo,
    String? descripcion,
  }) {
    return ImpuestoEntity(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      porcentaje: porcentaje ?? this.porcentaje,
      tipo: tipo ?? this.tipo,
      esExento: esExento ?? this.esExento,
      esDefault: esDefault ?? this.esDefault,
      activo: activo ?? this.activo,
      descripcion: descripcion ?? this.descripcion,
    );
  }
}

String etiquetaItbis(double tasaFraccion) {
  if (tasaFraccion <= 0) return 'ITBIS';
  final pct = tasaFraccion <= 1 ? tasaFraccion * 100 : tasaFraccion;
  final s = (pct - pct.round()).abs() < 0.001
      ? pct.round().toString()
      : pct.toStringAsFixed(2);
  return 'ITBIS ($s%)';
}
