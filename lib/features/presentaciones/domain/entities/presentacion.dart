class Presentacion {
  Presentacion({
    this.id,
    required this.nombre,
    required this.abreviatura,
    this.codigo = '',
    this.factorUnidades = 1,
    this.unidadMedidaId,
    this.activo = true,
  });

  final int? id;
  final String nombre;
  final String abreviatura;
  final String codigo;
  final double factorUnidades;
  final int? unidadMedidaId;
  final bool activo;

  Presentacion copyWith({
    int? id,
    String? nombre,
    String? abreviatura,
    String? codigo,
    double? factorUnidades,
    int? unidadMedidaId,
    bool? activo,
  }) {
    return Presentacion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      abreviatura: abreviatura ?? this.abreviatura,
      codigo: codigo ?? this.codigo,
      factorUnidades: factorUnidades ?? this.factorUnidades,
      unidadMedidaId: unidadMedidaId ?? this.unidadMedidaId,
      activo: activo ?? this.activo,
    );
  }
}
