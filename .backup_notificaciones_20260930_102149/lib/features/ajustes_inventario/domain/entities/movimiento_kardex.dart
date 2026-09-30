class MovimientoKardex {
  const MovimientoKardex({
    this.id,
    required this.productoId,
    required this.tipoMovimiento,
    required this.cantidad,
    required this.saldoActual,
    this.referenciaId,
    required this.motivo,
    required this.usuarioId,
    required this.fechaMovimiento,
  });
  final int? id;
  final int productoId;
  final String tipoMovimiento;
  final double cantidad;
  final double saldoActual;
  final int? referenciaId;
  final String motivo;
  final int usuarioId;
  final DateTime fechaMovimiento;
}
