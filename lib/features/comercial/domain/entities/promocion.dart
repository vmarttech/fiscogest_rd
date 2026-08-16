class Promocion {

  const Promocion({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    required this.valor,
    this.fechaInicio,
    this.fechaFin,
    this.activa = true,
  });
  final String id;
  final String nombre;
  final String descripcion;
  final String tipo;
  final double valor;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool activa;
}
