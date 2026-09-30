class Oferta {
  const Oferta({
    this.id,
    required this.nombre,
    required this.productoId,
    required this.cantidadMinima,
    required this.precioOferta,
    required this.vigenciaDesde,
    required this.vigenciaHasta,
    required this.estado,
  });

  final int? id;
  final String nombre;
  final int productoId;
  final int cantidadMinima;
  final double precioOferta;
  final DateTime vigenciaDesde;
  final DateTime vigenciaHasta;
  final String estado;
}
