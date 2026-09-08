/// Cada abono realizado sobre una cuenta por cobrar
/// Según manual sección 7: disminuye la deuda y aumenta caja
class AbonoCredito {
  const AbonoCredito({
    this.id,
    required this.cuentaId,
    required this.monto,
    required this.metodoPago,
    required this.fecha,
    this.nota,
    this.usuarioId,
  });

  final int? id;
  final int cuentaId;
  final double monto;
  final String metodoPago; // 'Efectivo', 'Transferencia', 'Otro'
  final DateTime fecha;
  final String? nota;
  final int? usuarioId;

  AbonoCredito copyWith({
    int? id,
    int? cuentaId,
    double? monto,
    String? metodoPago,
    DateTime? fecha,
    String? nota,
    int? usuarioId,
  }) {
    return AbonoCredito(
      id: id ?? this.id,
      cuentaId: cuentaId ?? this.cuentaId,
      monto: monto ?? this.monto,
      metodoPago: metodoPago ?? this.metodoPago,
      fecha: fecha ?? this.fecha,
      nota: nota ?? this.nota,
      usuarioId: usuarioId ?? this.usuarioId,
    );
  }
}
