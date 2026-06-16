class Negocio {
  final int? id;
  final String nombre;
  final String rnc;
  final String direccion;
  final String telefono;
  final String correo;
  final String actividadEconomica;

  Negocio({
    this.id,
    required this.nombre,
    required this.rnc,
    required this.direccion,
    required this.telefono,
    required this.correo,
    required this.actividadEconomica,
  });

  // Convertir de Objeto a Mapa (para guardar en BD)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'rnc': rnc,
      'direccion': direccion,
      'telefono': telefono,
      'correo': correo,
      'actividad_economica': actividadEconomica,
    };
  }

  // Convertir de Mapa a Objeto (para leer de BD)
  static Negocio fromMap(Map<String, dynamic> mapa) {
    return Negocio(
      id: mapa['id'],
      nombre: mapa['nombre'],
      rnc: mapa['rnc'],
      direccion: mapa['direccion'],
      telefono: mapa['telefono'],
      correo: mapa['correo'],
      actividadEconomica: mapa['actividad_economica'],
    );
  }
}