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
    this.ingresoMensual = 0.0,
    this.limiteCuotaMensual = 0.0,
    this.saldoPendiente = 0.0,
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
  final double ingresoMensual;
  final double limiteCuotaMensual;
  final double saldoPendiente;

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
    double? ingresoMensual,
    double? limiteCuotaMensual,
    double? saldoPendiente,
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
      ingresoMensual: ingresoMensual ?? this.ingresoMensual,
      limiteCuotaMensual: limiteCuotaMensual ?? this.limiteCuotaMensual,
      saldoPendiente: saldoPendiente ?? this.saldoPendiente,
    );
  }
}
