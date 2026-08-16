/// Entidad de dominio: Línea de detalle de una [Compra].
///
/// Cada instancia representa un producto incluido en la compra,
/// con cantidad, costo unitario, descuento por línea e importe.
class DetalleCompra {

  const DetalleCompra({
    required this.id,
    required this.compraId,
    required this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.costoUnitario,
    required this.descuentoPorcentaje,
    required this.montoDescuentoLinea,
    required this.subtotalLinea,
  });
  final String id;
  final String compraId;
  final String productoId;
  final String nombreProducto;
  final double cantidad;
  final double costoUnitario;
  final double descuentoPorcentaje;
  final double montoDescuentoLinea;
  final double subtotalLinea;

  double get importeBruto => cantidad * costoUnitario;

  DetalleCompra copyWith({
    String? id,
    String? compraId,
    String? productoId,
    String? nombreProducto,
    double? cantidad,
    double? costoUnitario,
    double? descuentoPorcentaje,
    double? montoDescuentoLinea,
    double? subtotalLinea,
  }) {
    return DetalleCompra(
      id: id ?? this.id,
      compraId: compraId ?? this.compraId,
      productoId: productoId ?? this.productoId,
      nombreProducto: nombreProducto ?? this.nombreProducto,
      cantidad: cantidad ?? this.cantidad,
      costoUnitario: costoUnitario ?? this.costoUnitario,
      descuentoPorcentaje: descuentoPorcentaje ?? this.descuentoPorcentaje,
      montoDescuentoLinea: montoDescuentoLinea ?? this.montoDescuentoLinea,
      subtotalLinea: subtotalLinea ?? this.subtotalLinea,
    );
  }
}
