class Pago {

  const Pago({
    this.id,
    required this.numero,
    required this.ventaId,
    this.clienteId,
    required this.monto,
    required this.metodoPago,
    required this.fecha,
    this.referencia,
    required this.tipoTransaccion,
  });
  final String? id;
  final String numero;
  final String ventaId;
  final String? clienteId;
  final double monto;
  final String metodoPago;
  final DateTime fecha;
  final String? referencia;
  final String tipoTransaccion;
}
