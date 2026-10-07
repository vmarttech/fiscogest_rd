class Transferencia {
  const Transferencia({
    this.id,
    required this.almacenOrigenId,
    required this.almacenDestinoId,
    required this.productoId,
    required this.cantidad,
    this.nota,
    required this.fecha,
    this.estado = 'registrada',
    this.origenNombre,
    this.destinoNombre,
    this.productoNombre,
    this.productoCodigo,
  });

  final int? id;
  final int almacenOrigenId;
  final int almacenDestinoId;
  final int productoId;
  final double cantidad;
  final String? nota;
  final DateTime fecha;
  final String estado;
  final String? origenNombre;
  final String? destinoNombre;
  final String? productoNombre;
  final String? productoCodigo;
}
