class Descuento {

  const Descuento({
    this.id,
    required this.codigo,
    required this.nombre,
    this.porcentaje,
    this.montoFijo,
    required this.fechaInicio,
    required this.fechaFin,
    this.activo = true,
    this.aplicableAProductoId,
    this.montoMinimo,
  });
  final String? id;
  final String codigo;
  final String nombre;
  final double? porcentaje;
  final double? montoFijo;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final bool activo;
  final String? aplicableAProductoId;
  final double? montoMinimo;
}
