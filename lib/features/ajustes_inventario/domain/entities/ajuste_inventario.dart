class AjusteInventario {

  const AjusteInventario({
    this.id,
    required this.idProducto,
    this.codigoBusqueda,
    required this.tipoAjuste,
    required this.cantidad,
    required this.motivo,
    required this.usuarioId,
    required this.fechaCreacion,
  });
  final int? id;
  final int idProducto;
  final String? codigoBusqueda;
  final String tipoAjuste;
  final double cantidad;
  final String motivo;
  final int usuarioId;
  final DateTime fechaCreacion;
}
