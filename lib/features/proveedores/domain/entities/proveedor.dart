class Proveedor {
  Proveedor({
    this.id,
    required this.nombreEmpresa,
    this.nombreContacto,
    this.rnc,
    this.telefono,
    this.celular,
    this.whatsApp,
    this.email,
    this.direccion,
    this.ciudad,
    this.provincia,
    this.limiteCredito = 0.0,
    this.diasCredito = 0,
    this.condicionesNota,
    this.estado = 'Activo',
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  final int? id;
  final String nombreEmpresa;
  final String? nombreContacto;
  final String? rnc;
  final String? telefono;
  final String? celular;
  final String? whatsApp;
  final String? email;
  final String? direccion;
  final String? ciudad;
  final String? provincia;
  final double limiteCredito;
  final int diasCredito;
  final String? condicionesNota;
  final String estado;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  bool get tieneCredito => limiteCredito > 0 || diasCredito > 0;

  String get direccionCompleta {
    final partes = <String>[];
    if (direccion?.isNotEmpty == true) partes.add(direccion!);
    if (ciudad?.isNotEmpty == true) partes.add(ciudad!);
    if (provincia?.isNotEmpty == true) partes.add(provincia!);
    return partes.join(', ');
  }

  Proveedor copyWith({
    int? id,
    String? nombreEmpresa,
    String? nombreContacto,
    String? rnc,
    String? telefono,
    String? celular,
    String? whatsApp,
    String? email,
    String? direccion,
    String? ciudad,
    String? provincia,
    double? limiteCredito,
    int? diasCredito,
    String? condicionesNota,
    String? estado,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return Proveedor(
      id: id ?? this.id,
      nombreEmpresa: nombreEmpresa ?? this.nombreEmpresa,
      nombreContacto: nombreContacto ?? this.nombreContacto,
      rnc: rnc ?? this.rnc,
      telefono: telefono ?? this.telefono,
      celular: celular ?? this.celular,
      whatsApp: whatsApp ?? this.whatsApp,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      ciudad: ciudad ?? this.ciudad,
      provincia: provincia ?? this.provincia,
      limiteCredito: limiteCredito ?? this.limiteCredito,
      diasCredito: diasCredito ?? this.diasCredito,
      condicionesNota: condicionesNota ?? this.condicionesNota,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}
