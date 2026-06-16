class Cliente {
  final int? id;
  final String nombre;
  final String identificacion;
  final String tipoIdentificacion;
  final String? direccion;
  final String? telefono;
  final String? correo;
  final bool exentoITBIS;
  final String regimenFiscal;
  final DateTime fechaRegistro; // ✅ AHORA ES DateTime

  Cliente({
    this.id,
    required this.nombre,
    required this.identificacion,
    required this.tipoIdentificacion,
    this.direccion,
    this.telefono,
    this.correo,
    required this.exentoITBIS,
    required this.regimenFiscal,
    required this.fechaRegistro,
  });

  // Convertir a Mapa para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'identificacion': identificacion,
      'tipoIdentificacion': tipoIdentificacion,
      'direccion': direccion,
      'telefono': telefono,
      'correo': correo,
      'exentoITBIS': exentoITBIS ? 1 : 0,
      'regimenFiscal': regimenFiscal,
      'fechaRegistro': fechaRegistro.toIso8601String(), // Guardamos como texto
    };
  }

  // Convertir de Mapa a Objeto
  static Cliente fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'],
      nombre: map['nombre'],
      identificacion: map['identificacion'],
      tipoIdentificacion: map['tipoIdentificacion'],
      direccion: map['direccion'],
      telefono: map['telefono'],
      correo: map['correo'],
      exentoITBIS: map['exentoITBIS'] == 1,
      regimenFiscal: map['regimenFiscal'],
      fechaRegistro: DateTime.parse(map['fechaRegistro']), // Convertimos a fecha
    );
  }
}