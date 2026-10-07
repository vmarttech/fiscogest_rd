class Unidad {
  Unidad({
    this.id,
    required this.nombre,
    required this.abreviatura,
    this.codigo = '',
    this.factorABase = 1,
    this.esBase = false,
    this.activo = true,
  });

  final int? id;
  final String nombre;
  final String abreviatura;
  final String codigo;
  final double factorABase;
  final bool esBase;
  final bool activo;

  Unidad copyWith({
    int? id,
    String? nombre,
    String? abreviatura,
    String? codigo,
    double? factorABase,
    bool? esBase,
    bool? activo,
  }) {
    return Unidad(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      abreviatura: abreviatura ?? this.abreviatura,
      codigo: codigo ?? this.codigo,
      factorABase: factorABase ?? this.factorABase,
      esBase: esBase ?? this.esBase,
      activo: activo ?? this.activo,
    );
  }
}
