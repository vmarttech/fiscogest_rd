class RecepcionElemento {

  const RecepcionElemento({
    this.id,
    this.recepcionId,
    this.productoId,
    this.productoNombre,
    this.cantidad,
    this.precioUnitario,
    this.subtotal,
    this.impuesto,
    this.total,
    this.lote,
    this.fechaVencimiento,
    this.observaciones,
  });
  final String? id;
  final String? recepcionId;
  final String? productoId;
  final String? productoNombre;
  final double? cantidad;
  final double? precioUnitario;
  final double? subtotal;
  final double? impuesto;
  final double? total;
  final String? lote;
  final DateTime? fechaVencimiento;
  final String? observaciones;

  RecepcionElemento copyWith({
    String? id,
    String? recepcionId,
    String? productoId,
    String? productoNombre,
    double? cantidad,
    double? precioUnitario,
    double? subtotal,
    double? impuesto,
    double? total,
    String? lote,
    DateTime? fechaVencimiento,
    String? observaciones,
  }) {
    return RecepcionElemento(
      id: id ?? this.id,
      recepcionId: recepcionId ?? this.recepcionId,
      productoId: productoId ?? this.productoId,
      productoNombre: productoNombre ?? this.productoNombre,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      subtotal: subtotal ?? this.subtotal,
      impuesto: impuesto ?? this.impuesto,
      total: total ?? this.total,
      lote: lote ?? this.lote,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      observaciones: observaciones ?? this.observaciones,
    );
  }

  @override
  String toString() {
    return 'RecepcionElemento(producto: $productoNombre, cantidad: $cantidad, total: $total)';
  }
}
