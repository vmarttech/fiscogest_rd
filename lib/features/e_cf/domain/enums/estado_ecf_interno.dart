/// Estados internos del pipeline e-CF (independientes del estado de la venta).
enum EstadoEcfInterno {
  borrador,
  validacionFallida,
  xmlListo,
  firmado,
  enviado,
  enProceso,
  aceptado,
  aceptadoObservacion,
  rechazado,
  anulado,
  errorTecnico;

  bool get esTerminalExito =>
      this == EstadoEcfInterno.aceptado ||
      this == EstadoEcfInterno.aceptadoObservacion;

  bool get esReintentable =>
      this == EstadoEcfInterno.errorTecnico ||
      this == EstadoEcfInterno.rechazado ||
      this == EstadoEcfInterno.validacionFallida ||
      this == EstadoEcfInterno.borrador;

  String get etiqueta {
    switch (this) {
      case EstadoEcfInterno.borrador:
        return 'Borrador';
      case EstadoEcfInterno.validacionFallida:
        return 'Validación fallida';
      case EstadoEcfInterno.xmlListo:
        return 'XML listo';
      case EstadoEcfInterno.firmado:
        return 'Firmado';
      case EstadoEcfInterno.enviado:
        return 'Enviado';
      case EstadoEcfInterno.enProceso:
        return 'En proceso DGII';
      case EstadoEcfInterno.aceptado:
        return 'Aceptado';
      case EstadoEcfInterno.aceptadoObservacion:
        return 'Aceptado c/obs.';
      case EstadoEcfInterno.rechazado:
        return 'Rechazado';
      case EstadoEcfInterno.anulado:
        return 'Anulado';
      case EstadoEcfInterno.errorTecnico:
        return 'Error técnico';
    }
  }
}
