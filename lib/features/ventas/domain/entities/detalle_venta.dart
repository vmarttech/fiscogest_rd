class DetalleVenta {
  const DetalleVenta({
    this.id,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.nombreProducto,
    this.subtotalLinea,
    this.ofertaId,
    this.ofertaNombre,
    this.precioOriginal,
    this.descuentoPorcentaje = 0,
    this.montoDescuento = 0,
    this.tasaImpuesto = 0,
  });

  final int? id;
  final int productoId;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final String? nombreProducto;
  final double? subtotalLinea;
  final String? ofertaId;
  final String? ofertaNombre;
  final double? precioOriginal;
  final double descuentoPorcentaje;
  final double montoDescuento;
  final double tasaImpuesto;

  DetalleVenta copyWith({
    int? id,
    int? productoId,
    int? cantidad,
    double? precioUnitario,
    double? subtotal,
    String? nombreProducto,
    double? subtotalLinea,
    String? ofertaId,
    String? ofertaNombre,
    double? precioOriginal,
    double? descuentoPorcentaje,
    double? montoDescuento,
    double? tasaImpuesto,
  }) {
    return DetalleVenta(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      subtotal: subtotal ?? this.subtotal,
      nombreProducto: nombreProducto ?? this.nombreProducto,
      subtotalLinea: subtotalLinea ?? this.subtotalLinea,
      ofertaId: ofertaId ?? this.ofertaId,
      ofertaNombre: ofertaNombre ?? this.ofertaNombre,
      precioOriginal: precioOriginal ?? this.precioOriginal,
      descuentoPorcentaje: descuentoPorcentaje ?? this.descuentoPorcentaje,
      montoDescuento: montoDescuento ?? this.montoDescuento,
      tasaImpuesto: tasaImpuesto ?? this.tasaImpuesto,
    );
  }
}
