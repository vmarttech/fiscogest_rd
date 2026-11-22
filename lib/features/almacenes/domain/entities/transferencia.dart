class Transferencia {
  const Transferencia({
    this.id,
    required this.almacenOrigenId,
    required this.almacenDestinoId,
    required this.productoId,
    required this.cantidad,
    this.observacion,
    required this.usuarioId,
    required this.fecha,
  });

  final int? id;
  final int almacenOrigenId;
  final int almacenDestinoId;
  final int productoId;
  final double cantidad;
  final String? observacion;
  final int usuarioId;
  final DateTime fecha;

  Transferencia copyWith({
    int? id,
    int? almacenOrigenId,
    int? almacenDestinoId,
    int? productoId,
    double? cantidad,
    String? observacion,
    int? usuarioId,
    DateTime? fecha,
  }) {
    return Transferencia(
      id: id ?? this.id,
      almacenOrigenId: almacenOrigenId ?? this.almacenOrigenId,
      almacenDestinoId: almacenDestinoId ?? this.almacenDestinoId,
      productoId: productoId ?? this.productoId,
      cantidad: cantidad ?? this.cantidad,
      observacion: observacion ?? this.observacion,
      usuarioId: usuarioId ?? this.usuarioId,
      fecha: fecha ?? this.fecha,
    );
  }
}
