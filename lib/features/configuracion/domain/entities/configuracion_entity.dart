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
    this.docMostrarLogo = true,
    this.docMostrarRnc = true,
    this.docMostrarDireccion = true,
    this.docMostrarTelefono = true,
    this.docMostrarCorreo = true,
    this.docMostrarNcf = true,
    this.docMostrarCliente = true,
    this.docMostrarItbisDesglose = true,
    this.docPiePagina = 'Gracias por su preferencia',
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
  final String formatoImpresion;
  final String formatoFecha;
  final double impuestoPorcentaje;
  final String idioma;

  final bool docMostrarLogo;
  final bool docMostrarRnc;
  final bool docMostrarDireccion;
  final bool docMostrarTelefono;
  final bool docMostrarCorreo;
  final bool docMostrarNcf;
  final bool docMostrarCliente;
  final bool docMostrarItbisDesglose;
  final String docPiePagina;

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
    bool? docMostrarLogo,
    bool? docMostrarRnc,
    bool? docMostrarDireccion,
    bool? docMostrarTelefono,
    bool? docMostrarCorreo,
    bool? docMostrarNcf,
    bool? docMostrarCliente,
    bool? docMostrarItbisDesglose,
    String? docPiePagina,
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
      docMostrarLogo: docMostrarLogo ?? this.docMostrarLogo,
      docMostrarRnc: docMostrarRnc ?? this.docMostrarRnc,
      docMostrarDireccion: docMostrarDireccion ?? this.docMostrarDireccion,
      docMostrarTelefono: docMostrarTelefono ?? this.docMostrarTelefono,
      docMostrarCorreo: docMostrarCorreo ?? this.docMostrarCorreo,
      docMostrarNcf: docMostrarNcf ?? this.docMostrarNcf,
      docMostrarCliente: docMostrarCliente ?? this.docMostrarCliente,
      docMostrarItbisDesglose:
          docMostrarItbisDesglose ?? this.docMostrarItbisDesglose,
      docPiePagina: docPiePagina ?? this.docPiePagina,
    );
  }
}
