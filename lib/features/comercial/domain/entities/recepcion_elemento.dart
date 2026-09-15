class DetalleRecepcion {
  const DetalleRecepcion({
    this.id,
    this.productoId,
    this.productoNombre,
    this.cantidadPedida,
    this.cantidadRecibida,
    this.costoUnitario,
    this.fleteUnitario = 0.0,
    this.seguroUnitario = 0.0,
    this.arancelesUnitario = 0.0,
    this.gastosUnitario = 0.0,
    this.subtotal,
    this.diferencia,
    this.motivoDiferencia,
  });

  final int? id;
  final int? productoId;
  final String? productoNombre;
  final double? cantidadPedida;
  final double? cantidadRecibida;
  final double? costoUnitario;
  final double fleteUnitario;
  final double seguroUnitario;
  final double arancelesUnitario;
  final double gastosUnitario;
  final double? subtotal;
  final double? diferencia;
  final String? motivoDiferencia;

  double get costoAdquisicion =>
      (costoUnitario ?? 0) + fleteUnitario + seguroUnitario + arancelesUnitario + gastosUnitario;

  DetalleRecepcion copyWith({
    int? id,
    int? productoId,
    String? productoNombre,
    double? cantidadPedida,
    double? cantidadRecibida,
    double? costoUnitario,
    double? fleteUnitario,
    double? seguroUnitario,
    double? arancelesUnitario,
    double? gastosUnitario,
    double? subtotal,
    double? diferencia,
    String? motivoDiferencia,
  }) {
    return DetalleRecepcion(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      productoNombre: productoNombre ?? this.productoNombre,
      cantidadPedida: cantidadPedida ?? this.cantidadPedida,
      cantidadRecibida: cantidadRecibida ?? this.cantidadRecibida,
      costoUnitario: costoUnitario ?? this.costoUnitario,
      fleteUnitario: fleteUnitario ?? this.fleteUnitario,
      seguroUnitario: seguroUnitario ?? this.seguroUnitario,
      arancelesUnitario: arancelesUnitario ?? this.arancelesUnitario,
      gastosUnitario: gastosUnitario ?? this.gastosUnitario,
      subtotal: subtotal ?? this.subtotal,
      diferencia: diferencia ?? this.diferencia,
      motivoDiferencia: motivoDiferencia ?? this.motivoDiferencia,
    );
  }

  @override
  String toString() {
    return 'DetalleRecepcion(producto: $productoNombre, pedida: $cantidadPedida, recibida: $cantidadRecibida)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetalleRecepcion && other.id == id;
  }

  @override
  int get hashCode => (id ?? 0).hashCode;
}

class RecepcionElemento {
  const RecepcionElemento({
    this.id,
    this.recepcionId,
    this.productoId,
    this.productoNombre,
    this.cantidad,
    this.precioUnitario,
    this.fleteUnitario = 0.0,
    this.seguroUnitario = 0.0,
    this.arancelesUnitario = 0.0,
    this.gastosUnitario = 0.0,
    this.subtotal,
    this.impuesto,
    this.total,
    this.lote,
    this.fechaVencimiento,
    this.observaciones,
  });

  final int? id;
  final int? recepcionId;
  final int? productoId;
  final String? productoNombre;
  final double? cantidad;
  final double? precioUnitario;
  final double fleteUnitario;
  final double seguroUnitario;
  final double arancelesUnitario;
  final double gastosUnitario;
  final double? subtotal;
  final double? impuesto;
  final double? total;
  final String? lote;
  final DateTime? fechaVencimiento;
  final String? observaciones;

  double get costoAdquisicion =>
      (precioUnitario ?? 0) + fleteUnitario + seguroUnitario + arancelesUnitario + gastosUnitario;

  RecepcionElemento copyWith({
    int? id,
    int? recepcionId,
    int? productoId,
    String? productoNombre,
    double? cantidad,
    double? precioUnitario,
    double? fleteUnitario,
    double? seguroUnitario,
    double? arancelesUnitario,
    double? gastosUnitario,
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
      fleteUnitario: fleteUnitario ?? this.fleteUnitario,
      seguroUnitario: seguroUnitario ?? this.seguroUnitario,
      arancelesUnitario: arancelesUnitario ?? this.arancelesUnitario,
      gastosUnitario: gastosUnitario ?? this.gastosUnitario,
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
