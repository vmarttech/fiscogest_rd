class Devolucion {
  const Devolucion({
    this.id,
    required this.numero,
    required this.ventaId,
    required this.productoId,
    required this.cantidadDevuelta,
    required this.montoReembolsado,
    required this.motivo,
    required this.fecha,
    required this.estado,
    this.createdAt,
  });

  final int? id;
  final String numero;
  final int ventaId;
  final int productoId;
  final double cantidadDevuelta;
  final double montoReembolsado;
  final String motivo;
  final DateTime fecha;
  final String estado;
  final DateTime? createdAt;
}
