class ClienteCompleto {

  ClienteCompleto({
    this.id,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.correo,
    required this.rncCedula,
    this.activo = true,
    this.observaciones = '',
    this.historial = 'Cliente registrado en el sistema.',
  });
  final int? id;
  final String nombre;
  final String direccion;
  final String telefono;
  final String correo;
  final String rncCedula;
  final bool activo;
  final String observaciones;
  final String historial;

  ClienteCompleto copyWith({
    int? id,
    String? nombre,
    String? direccion,
    String? telefono,
    String? correo,
    String? rncCedula,
    bool? activo,
    String? observaciones,
    String? historial,
  }) {
    return ClienteCompleto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      rncCedula: rncCedula ?? this.rncCedula,
      activo: activo ?? this.activo,
      observaciones: observaciones ?? this.observaciones,
      historial: historial ?? this.historial,
    );
  }
}
