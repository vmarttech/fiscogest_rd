enum EstadoConteo {
  pendiente,
  abierto,
  enProceso,
  conciliado,
  aprobado,
  cancelado;

  String get etiqueta {
    switch (this) {
      case EstadoConteo.pendiente: return 'Pendiente';
      case EstadoConteo.abierto: return 'Abierto';
      case EstadoConteo.enProceso: return 'En proceso de conteo';
      case EstadoConteo.conciliado: return 'Conciliado';
      case EstadoConteo.aprobado: return 'Aprobado y cerrado';
      case EstadoConteo.cancelado: return 'Cancelado';
    }
  }
}
