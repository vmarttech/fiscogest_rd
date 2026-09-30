/// Entidad de dominio: Línea de detalle de una [Compra].
class DetalleCompra {
  const DetalleCompra({
    required this.id,
    required this.compraId,
    required this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.costoUnitario,
    this.fleteUnitario = 0.0,
    this.seguroUnitario = 0.0,
    this.arancelesUnitario = 0.0,
    this.gastosUnitario = 0.0,
    required this.costoAdquisicion,
    this.descuentoPorcentaje = 0.0,
    this.montoDescuentoLinea = 0.0,
    required this.subtotalLinea,
    this.baseImponibleLinea = 0.0,
    this.tasaImpuestoLinea = 0.0,
    this.itbisLinea = 0.0,
    this.totalLinea = 0.0,
  });

  final int id;
  final int compraId;
  final int productoId;
  final String nombreProducto;
  final double cantidad;
  final double costoUnitario;
  final double fleteUnitario;
  final double seguroUnitario;
  final double arancelesUnitario;
  final double gastosUnitario;
  final double costoAdquisicion;
  final double descuentoPorcentaje;
  final double montoDescuentoLinea;
  final double subtotalLinea;
  final double baseImponibleLinea;
  final double tasaImpuestoLinea;
  final double itbisLinea;
  final double totalLinea;

  double get importeBruto => cantidad * costoUnitario;

  DetalleCompra copyWith({
    int? id,
    int? compraId,
    int? productoId,
    String? nombreProducto,
    double? cantidad,
    double? costoUnitario,
    double? fleteUnitario,
    double? seguroUnitario,
    double? arancelesUnitario,
    double? gastosUnitario,
    double? costoAdquisicion,
    double? descuentoPorcentaje,
    double? montoDescuentoLinea,
    double? subtotalLinea,
    double? baseImponibleLinea,
    double? tasaImpuestoLinea,
    double? itbisLinea,
    double? totalLinea,
  }) {
    return DetalleCompra(
      id: id ?? this.id,
      compraId: compraId ?? this.compraId,
      productoId: productoId ?? this.productoId,
      nombreProducto: nombreProducto ?? this.nombreProducto,
      cantidad: cantidad ?? this.cantidad,
      costoUnitario: costoUnitario ?? this.costoUnitario,
      fleteUnitario: fleteUnitario ?? this.fleteUnitario,
      seguroUnitario: seguroUnitario ?? this.seguroUnitario,
      arancelesUnitario: arancelesUnitario ?? this.arancelesUnitario,
      gastosUnitario: gastosUnitario ?? this.gastosUnitario,
      costoAdquisicion: costoAdquisicion ?? this.costoAdquisicion,
      descuentoPorcentaje: descuentoPorcentaje ?? this.descuentoPorcentaje,
      montoDescuentoLinea: montoDescuentoLinea ?? this.montoDescuentoLinea,
      subtotalLinea: subtotalLinea ?? this.subtotalLinea,
      baseImponibleLinea: baseImponibleLinea ?? this.baseImponibleLinea,
      tasaImpuestoLinea: tasaImpuestoLinea ?? this.tasaImpuestoLinea,
      itbisLinea: itbisLinea ?? this.itbisLinea,
      totalLinea: totalLinea ?? this.totalLinea,
    );
  }
}
