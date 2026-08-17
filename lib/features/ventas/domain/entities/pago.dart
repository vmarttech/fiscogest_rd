class Pago {
  const Pago({
    this.id,
    required this.cuentaCobrarId,
    required this.clienteId,
    required this.fecha,
    required this.monto,
    required this.formaPago,
    this.referencia,
    this.observaciones,
    this.createdAt,
  });

  final int? id;
  final int cuentaCobrarId;
  final int clienteId;
  final DateTime fecha;
  final double monto;
  final String formaPago;
  final String? referencia;
  final String? observaciones;
  final DateTime? createdAt;
}
