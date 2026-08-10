class Proveedor {

  Proveedor({
    this.id,
    required this.nombre,
    required this.contacto,
    required this.direccion,
    required this.telefono,
    required this.correo,
    required this.rnc,
    this.activo = true,
  });
  final int? id;
  final String nombre;
  final String contacto;
  final String direccion;
  final String telefono;
  final String correo;
  final String rnc;
  final bool activo;

  Proveedor copyWith({
    int? id,
    String? nombre,
    String? contacto,
    String? direccion,
    String? telefono,
    String? correo,
    String? rnc,
    bool? activo,
  }) {
    return Proveedor(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      contacto: contacto ?? this.contacto,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      rnc: rnc ?? this.rnc,
      activo: activo ?? this.activo,
    );
  }
}
