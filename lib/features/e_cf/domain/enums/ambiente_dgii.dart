enum AmbienteDgii {
  /// Desarrollo local / sin red DGII.
  deshabilitado,
  /// Ambiente de pruebas DGII (precertificación).
  precertificacion,
  /// Certificación formal.
  certificacion,
  /// Producción.
  produccion;

  String get etiqueta {
    switch (this) {
      case AmbienteDgii.deshabilitado:
        return 'Deshabilitado';
      case AmbienteDgii.precertificacion:
        return 'Precertificación';
      case AmbienteDgii.certificacion:
        return 'Certificación';
      case AmbienteDgii.produccion:
        return 'Producción';
    }
  }

  bool get permiteEnvio =>
      this == AmbienteDgii.precertificacion ||
      this == AmbienteDgii.certificacion ||
      this == AmbienteDgii.produccion;
}
