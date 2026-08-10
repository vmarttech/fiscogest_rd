import 'package:equatable/equatable.dart';

class Proveedor extends Equatable {
  const Proveedor({
    this.id,
    required this.nombre,
    required this.contacto,
    required this.direccion,
    required this.telefono,
    required this.correo,
    required this.rnc,
    required this.activo,
  });

  final int? id;
  final String nombre;
  final String contacto;
  final String direccion;
  final String telefono;
  final String correo;
  final String rnc;
  final bool activo;

  // ✅ Método copyWith AGREGADO COMPLETO, cada parámetro IGUAL nombre/tipo a campos existentes
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

  // ✅ Lista props COMPLETADA Y CERRADA: incluye TODOS los campos declarados
  @override
  List<Object?> get props => [
        id,
        nombre,
        contacto,
        direccion,
        telefono,
        correo,
        rnc,
        activo,
      ];
}
