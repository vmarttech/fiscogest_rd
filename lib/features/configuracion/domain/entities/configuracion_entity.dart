class ConfiguracionEntity {

  const ConfiguracionEntity({
    required this.id,
    required this.nombreComercial,
    required this.razonSocial,
    required this.rnc,
    required this.direccion,
    required this.telefono,
    required this.correo,
    required this.logoUrl,
    required this.moneda,
    required this.zonaHoraria,
    required this.formatoImpresion,
    required this.formatoFecha,
    required this.impuestoPorcentaje,
    required this.idioma,
  });
  final String id;
  final String nombreComercial;
  final String razonSocial;
  final String rnc;
  final String direccion;
  final String telefono;
  final String correo;
  final String logoUrl;
  final String moneda;
  final String zonaHoraria;
  final String formatoImpresion; // e.g., 'Ticket 80mm', 'Factura Carta (PDF)'
  final String formatoFecha;
  final double impuestoPorcentaje;
  final String idioma;

  ConfiguracionEntity copyWith({
    String? id,
    String? nombreComercial,
    String? razonSocial,
    String? rnc,
    String? direccion,
    String? telefono,
    String? correo,
    String? logoUrl,
    String? moneda,
    String? zonaHoraria,
    String? formatoImpresion,
    String? formatoFecha,
    double? impuestoPorcentaje,
    String? idioma,
  }) {
    return ConfiguracionEntity(
      id: id ?? this.id,
      nombreComercial: nombreComercial ?? this.nombreComercial,
      razonSocial: razonSocial ?? this.razonSocial,
      rnc: rnc ?? this.rnc,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      logoUrl: logoUrl ?? this.logoUrl,
      moneda: moneda ?? this.moneda,
      zonaHoraria: zonaHoraria ?? this.zonaHoraria,
      formatoImpresion: formatoImpresion ?? this.formatoImpresion,
      formatoFecha: formatoFecha ?? this.formatoFecha,
      impuestoPorcentaje: impuestoPorcentaje ?? this.impuestoPorcentaje,
      idioma: idioma ?? this.idioma,
    );
  }
}
