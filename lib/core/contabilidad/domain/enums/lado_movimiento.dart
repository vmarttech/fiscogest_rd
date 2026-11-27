/// Lado del movimiento de linea dentro de un asiento (debito / credito).
enum LadoMovimiento {
  debe,
  haber,
}

extension LadoMovimientoOps on LadoMovimiento {
  bool get esDebe => this == LadoMovimiento.debe;

  bool get esHaber => this == LadoMovimiento.haber;

  // Signo para balance: debito positivo, credito negativo.
  int get signo => esDebe ? 1 : -1;

  // Lado opuesto, util para reversas y asientos por contrapartida.
  LadoMovimiento get opuesto => esDebe ? LadoMovimiento.haber : LadoMovimiento.debe;

  String get claveI18n => switch (this) {
        LadoMovimiento.debe => 'mov_lado_debe',
        LadoMovimiento.haber => 'mov_lado_haber',
      };
}
