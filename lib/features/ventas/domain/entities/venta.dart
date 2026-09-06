class Venta {
  const Venta({
    this.id,
    required this.numero,
    this.numeroFactura,
    required this.clienteId,
    this.nombreCliente,
    required this.fecha,
    required this.detalles,
    required this.subtotal,
    required this.itbis,
    this.costoEnvio = 0.0,
    required this.total,
    required this.tipoPago,
    required this.esCredito,
    this.cotizacionOrigenId,
    this.apartadoOrigenId,
    this.usuarioId,
    this.createdAt,
    this.descuentoId,
    this.descuentoNombre,
    this.montoDescuento = 0.0,
  });
  final int? id;
  final String numero;
  final String? numeroFactura;
  final int clienteId;
  final String? nombreCliente;
  final DateTime fecha;
  final List<dynamic> detalles;
  final double subtotal;
  final double itbis;
  final double costoEnvio;
  final double total;
  final String tipoPago;
  final bool esCredito;
  final int? cotizacionOrigenId;
  final int? apartadoOrigenId;
  final int? usuarioId;
  final DateTime? createdAt;
  final int? descuentoId;
  final String? descuentoNombre;
  final double montoDescuento;
}
