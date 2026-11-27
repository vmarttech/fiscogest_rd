/// Estado de un asiento contable dentro del ciclo contable.
enum EstadoAsiento {
  borrador,
  pendiente,
  aprobado,
  contabilizado,
  anulado,
}

extension EstadoAsientoOps on EstadoAsiento {
  // Solo los estados iniciales pueden editarse o eliminarse.
  bool get esEditable =>
      this == EstadoAsiento.borrador || this == EstadoAsiento.pendiente;

  bool get esBorrador => this == EstadoAsiento.borrador;
  bool get esPendiente => this == EstadoAsiento.pendiente;
  bool get esAprobado => this == EstadoAsiento.aprobado;
  bool get esContabilizado => this == EstadoAsiento.contabilizado;
  bool get esAnulado => this == EstadoAsiento.anulado;

  // Reglas de transicion de la maquina de estados.
  // Aprobacion: borrador y pendiente pueden avanzar en el flujo de aprobacion.
  bool get puedeAprobar => esBorrador || esPendiente;

  // Contabilizacion: todo estado no terminal puede publicarse en el libro;
  // contabilizado y anulado quedan fuera (inmutabilidad).
  bool get puedeContabilizar => esBorrador || esPendiente || esAprobado;

  // Anulacion (reversa): solo un asiento ya contabilizado puede anularse.
  bool get puedeAnular => esContabilizado;

  // Clave de traduccion para i18n.
  String get claveI18n => switch (this) {
        EstadoAsiento.borrador => 'asiento_estado_borrador',
        EstadoAsiento.pendiente => 'asiento_estado_pendiente',
        EstadoAsiento.aprobado => 'asiento_estado_aprobado',
        EstadoAsiento.contabilizado => 'asiento_estado_contabilizado',
        EstadoAsiento.anulado => 'asiento_estado_anulado',
      };
}
