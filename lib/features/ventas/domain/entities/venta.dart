class Venta {
  const Venta({
    this.id,
    required this.numero,
    required this.clienteId,
    required this.usuarioId,
    required this.fecha,
    required this.detalles,
    required this.subtotal,
    required this.itbis,
    required this.total,
    required this.tipoPago,
    this.esCredito = false,
    this.cotizacionOrigenId,
    this.apartadoOrigenId,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String numero;
  final int clienteId;
  final int usuarioId;
  final DateTime fecha;
  final List<DetalleVenta> detalles;
  final double subtotal;
  final double itbis;
  final double total;
  final String tipoPago;
  final bool esCredito;
  final int? cotizacionOrigenId;
  final int? apartadoOrigenId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class DetalleVenta {
  const DetalleVenta({
    required this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotalLinea,
    this.descuentoPorcentaje,
    this.montoDescuento,
  });

  final int productoId;
  final String nombreProducto;
  final double cantidad;
  final double precioUnitario;
  final double subtotalLinea;
  final double? descuentoPorcentaje;
  final double? montoDescuento;
}
