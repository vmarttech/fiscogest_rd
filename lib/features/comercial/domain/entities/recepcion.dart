class Recepcion {

  const Recepcion({
    this.id,
    this.fechaRecepcion,
    this.numeroDocumento,
    this.proveedorId,
    this.proveedorNombre,
    this.tipoComprobante,
    this.numeroComprobante,
    this.fechaComprobante,
    this.subtotal,
    this.impuesto,
    this.total,
    this.estado,
    this.observaciones,
    this.usuarioResponsable,
    this.fechaCreacion,
    this.fechaActualizacion,
  });
  final String? id;
  final DateTime? fechaRecepcion;
  final String? numeroDocumento;
  final String? proveedorId;
  final String? proveedorNombre;
  final String? tipoComprobante;
  final String? numeroComprobante;
  final DateTime? fechaComprobante;
  final double? subtotal;
  final double? impuesto;
  final double? total;
  final String? estado;
  final String? observaciones;
  final String? usuarioResponsable;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  Recepcion copyWith({
    String? id,
    DateTime? fechaRecepcion,
    String? numeroDocumento,
    String? proveedorId,
    String? proveedorNombre,
    String? tipoComprobante,
    String? numeroComprobante,
    DateTime? fechaComprobante,
    double? subtotal,
    double? impuesto,
    double? total,
    String? estado,
    String? observaciones,
    String? usuarioResponsable,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return Recepcion(
      id: id ?? this.id,
      fechaRecepcion: fechaRecepcion ?? this.fechaRecepcion,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      proveedorId: proveedorId ?? this.proveedorId,
      proveedorNombre: proveedorNombre ?? this.proveedorNombre,
      tipoComprobante: tipoComprobante ?? this.tipoComprobante,
      numeroComprobante: numeroComprobante ?? this.numeroComprobante,
      fechaComprobante: fechaComprobante ?? this.fechaComprobante,
      subtotal: subtotal ?? this.subtotal,
      impuesto: impuesto ?? this.impuesto,
      total: total ?? this.total,
      estado: estado ?? this.estado,
      observaciones: observaciones ?? this.observaciones,
      usuarioResponsable: usuarioResponsable ?? this.usuarioResponsable,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  @override
  String toString() {
    return 'Recepcion(id: $id, numeroDocumento: $numeroDocumento, total: $total, estado: $estado)';
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
