class Descuento {
  const Descuento({
    this.id,
    required this.nombre,
    required this.tipo,
    required this.valor,
    required this.aplicaA,
    this.referenciaId,
    required this.vigenciaDesde,
    required this.vigenciaHasta,
    required this.estado,
  });

  final int? id;
  final String nombre;
  final String tipo;
  final double valor;
  final String aplicaA;
  final int? referenciaId;
  final DateTime vigenciaDesde;
  final DateTime vigenciaHasta;
  final String estado;
}
