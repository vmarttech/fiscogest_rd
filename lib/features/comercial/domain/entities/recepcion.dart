class Recepcion {
  const Recepcion({
    this.id,
    this.compraId,
    this.proveedorId,
    this.proveedorNombre,
    this.fechaRecepcion,
    this.estado,
    this.numeroDocumento,
    this.tipoComprobante,
    this.numeroComprobante,
    this.fechaComprobante,
    this.subtotal,
    this.impuesto,
    this.total,
    this.observaciones,
    this.detalles,
    this.usuarioResponsable,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  final String? id;
  final String? compraId;
  final String? proveedorId;
  final String? proveedorNombre;
  final DateTime? fechaRecepcion;
  final String? estado;
  final String? numeroDocumento;
  final String? tipoComprobante;
  final String? numeroComprobante;
  final DateTime? fechaComprobante;
  final double? subtotal;
  final double? impuesto;
  final double? total;
  final String? observaciones;
  final List<DetalleRecepcion>? detalles;
  final String? usuarioResponsable;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  Recepcion copyWith({
    String? id,
    String? compraId,
    String? proveedorId,
    String? proveedorNombre,
    DateTime? fechaRecepcion,
    String? estado,
    String? numeroDocumento,
    String? tipoComprobante,
    String? numeroComprobante,
    DateTime? fechaComprobante,
    double? subtotal,
    double? impuesto,
    double? total,
    String? observaciones,
    List<DetalleRecepcion>? detalles,
    String? usuarioResponsable,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return Recepcion(
      id: id ?? this.id,
      compraId: compraId ?? this.compraId,
      proveedorId: proveedorId ?? this.proveedorId,
      proveedorNombre: proveedorNombre ?? this.proveedorNombre,
      fechaRecepcion: fechaRecepcion ?? this.fechaRecepcion,
      estado: estado ?? this.estado,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      tipoComprobante: tipoComprobante ?? this.tipoComprobante,
      numeroComprobante: numeroComprobante ?? this.numeroComprobante,
      fechaComprobante: fechaComprobante ?? this.fechaComprobante,
      subtotal: subtotal ?? this.subtotal,
      impuesto: impuesto ?? this.impuesto,
      total: total ?? this.total,
      observaciones: observaciones ?? this.observaciones,
      detalles: detalles ?? this.detalles,
      usuarioResponsable: usuarioResponsable ?? this.usuarioResponsable,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  @override
  String toString() {
    return 'Recepcion(id: $id, numeroDocumento: $numeroDocumento, compraId: $compraId, total: $total, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recepcion &&
        other.id == id &&
        other.numeroDocumento == numeroDocumento;
  }

  @override
  int get hashCode => id.hashCode ^ numeroDocumento.hashCode;
}

class DetalleRecepcion {
  const DetalleRecepcion({
    this.id,
    this.productoId,
    this.productoNombre,
    this.cantidadPedida,
    this.cantidadRecibida,
    this.costoUnitario,
    this.subtotal,
    this.diferencia,
    this.motivoDiferencia,
  });

  final String? id;
  final String? productoId;
  final String? productoNombre;
  final double? cantidadPedida;
  final double? cantidadRecibida;
  final double? costoUnitario;
  final double? subtotal;
  final double? diferencia;
  final String? motivoDiferencia;

  DetalleRecepcion copyWith({
    String? id,
    String? productoId,
    String? productoNombre,
    double? cantidadPedida,
    double? cantidadRecibida,
    double? costoUnitario,
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
  int get hashCode => id.hashCode;
}
