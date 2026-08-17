class Oferta {

  const Oferta({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    required this.valor,
    required this.validoDesde,
    required this.validoHasta,
    this.activa = true,
    this.productosAplicables,
    this.usosMaximos,
    this.usosRealizados = 0,
  });
  final String? id;
  final String nombre;
  final String descripcion;
  final String tipo;
  final double valor;
  final DateTime validoDesde;
  final DateTime validoHasta;
  final bool activa;
  final List<String>? productosAplicables;
  final int? usosMaximos;
  final int usosRealizados;
}
