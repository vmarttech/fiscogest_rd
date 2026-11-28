enum EstadoPeriodo {
  abierto,
  cerrado,
}

extension EstadoPeriodoX on EstadoPeriodo {
  bool get permiteAsientos => this == EstadoPeriodo.abierto;
}
