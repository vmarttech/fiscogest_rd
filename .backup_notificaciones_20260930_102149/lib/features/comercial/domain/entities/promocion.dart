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
    this.minimoCantidad,
    this.minimoMonto,
  });
  final int id;
  final String nombre;
  final String descripcion;
  final String tipo;
  final double valor;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool activa;
  final int? minimoCantidad;
  final double? minimoMonto;
  bool estaVigente(DateTime fechaReferencia) {
    if (fechaInicio != null && fechaReferencia.isBefore(fechaInicio!)) {
      return false;
    }
    if (fechaFin != null && fechaReferencia.isAfter(fechaFin!)) return false;
    return activa;
  }

  bool aplicaAProducto(int? idProducto) => true;
  bool aplicaACategoriaCliente(String? idCategoria) => true;
}
