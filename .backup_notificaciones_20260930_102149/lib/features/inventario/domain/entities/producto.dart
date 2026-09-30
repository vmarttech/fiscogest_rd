class Producto {
  Producto({
    this.id,
    required this.codigo,
    this.codigoBarras,
    required this.nombre,
    this.descripcion,
    required this.precioCompra,
    required this.precioVenta,
    this.margenGanancia,
    this.precioMinimo,
    this.precioMayorista,
    this.precioEspecial,
    this.fechaInicioOferta,
    this.fechaFinOferta,
    this.gastosAsociados = 0,
    this.costoPromedio = 0.0,
    this.stock,
    this.stockMinimo,
    this.stockMaximo,
    required this.categoriaId,
    required this.marcaId,
    required this.unidadMedidaId,
    required this.activo,
  });

  final int? id;
  final String codigo;
  final String? codigoBarras;
  final String nombre;
  final String? descripcion;
  final double precioCompra;
  final double gastosAsociados;
  final double precioVenta;
  final double? margenGanancia;
  final double? precioMinimo;
  final double? precioMayorista;
  final double? precioEspecial;
  final DateTime? fechaInicioOferta;
  final DateTime? fechaFinOferta;
  final double costoPromedio;
  final double? stock;
  final double? stockMinimo;
  final double? stockMaximo;
  final int categoriaId;
  final int marcaId;
  final int unidadMedidaId;
  final bool activo;

  double get costoReal => precioCompra + gastosAsociados;

  double calcularMargen() {
    final cr = costoReal;
    if (cr <= 0) return 0;
    return ((precioVenta - cr) / cr) * 100;
  }

  static double calcularPrecioDesdeMargen(double costo, double margen) {
    return costo * (1 + margen / 100);
  }

  // Cálculo de Costo Promedio Ponderado al recibir nueva compra
  double recalcularCostoPromedio(double cantidadAnterior, double cantidadNueva, double costoUnitarioNuevo) {
    if (cantidadAnterior <= 0) return costoUnitarioNuevo;
    final inventarioAnterior = cantidadAnterior * costoPromedio;
    final montoNuevaEntrada = cantidadNueva * costoUnitarioNuevo;
    return (inventarioAnterior + montoNuevaEntrada) / (cantidadAnterior + cantidadNueva);
  }

  bool get ofertaVigente {
    if (precioEspecial == null || precioEspecial! <= 0) return false;
    final hoy = DateTime.now();
    final inicio = fechaInicioOferta ?? DateTime(2000);
    final fin = fechaFinOferta ?? DateTime(2100);
    return hoy.isAfter(inicio) && hoy.isBefore(fin.add(const Duration(days: 1)));
  }

  bool precioVentaEsValido() {
    if (precioMinimo == null) return true;
    return precioVenta >= precioMinimo!;
  }

  Producto copyWith({
    int? id,
    String? codigo,
    String? codigoBarras,
    String? nombre,
    String? descripcion,
    double? precioCompra,
    double? gastosAsociados,
    double? precioVenta,
    double? margenGanancia,
    double? precioMinimo,
    double? precioMayorista,
    double? precioEspecial,
    DateTime? fechaInicioOferta,
    DateTime? fechaFinOferta,
    double? costoPromedio,
    double? stock,
    double? stockMinimo,
    double? stockMaximo,
    int? categoriaId,
    int? marcaId,
    int? unidadMedidaId,
    bool? activo,
  }) {
    return Producto(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precioCompra: precioCompra ?? this.precioCompra,
      gastosAsociados: gastosAsociados ?? this.gastosAsociados,
      precioVenta: precioVenta ?? this.precioVenta,
      margenGanancia: margenGanancia ?? this.margenGanancia,
      precioMinimo: precioMinimo ?? this.precioMinimo,
      precioMayorista: precioMayorista ?? this.precioMayorista,
      precioEspecial: precioEspecial ?? this.precioEspecial,
      fechaInicioOferta: fechaInicioOferta ?? this.fechaInicioOferta,
      fechaFinOferta: fechaFinOferta ?? this.fechaFinOferta,
      costoPromedio: costoPromedio ?? this.costoPromedio,
      stock: stock ?? this.stock,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      stockMaximo: stockMaximo ?? this.stockMaximo,
      categoriaId: categoriaId ?? this.categoriaId,
      marcaId: marcaId ?? this.marcaId,
      unidadMedidaId: unidadMedidaId ?? this.unidadMedidaId,
      activo: activo ?? this.activo,
    );
  }
}
