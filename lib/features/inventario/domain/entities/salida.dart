class Salida {
  Salida({
    this.id,
    required this.productoId,
    required this.cantidad,
    required this.motivo,
    required this.usuario,
    required this.fecha,
  });

  final int? id;
  final int productoId;
  final int cantidad;
  final String motivo;
  final String usuario;
  final DateTime fecha;
}