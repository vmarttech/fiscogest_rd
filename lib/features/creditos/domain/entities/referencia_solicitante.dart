class ReferenciaSolicitante {
  const ReferenciaSolicitante({
    this.id,
    this.solicitudId,
    this.nombre = '',
    this.relacion = '',
    this.telefono = '',
    this.direccion = '',
    this.orden = 1,
  });

  final int? id;
  final int? solicitudId;
  final String nombre;
  final String relacion;
  final String telefono;
  final String direccion;
  final int orden;

  ReferenciaSolicitante copyWith({
    int? id,
    int? solicitudId,
    String? nombre,
    String? relacion,
    String? telefono,
    String? direccion,
    int? orden,
  }) {
    return ReferenciaSolicitante(
      id: id ?? this.id,
      solicitudId: solicitudId ?? this.solicitudId,
      nombre: nombre ?? this.nombre,
      relacion: relacion ?? this.relacion,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      orden: orden ?? this.orden,
    );
  }
}
