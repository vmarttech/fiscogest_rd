/// Contrato abstracto para actualización de costos de productos.
abstract class IProductoRepository {
  /// Actualiza el costo unitario del producto tras confirmación de compra.
  Future<void> actualizarCostoProducto({
    required String productoId,
    required double costoUnitario,
    required double cantidadAnterior,
    required double cantidadMovimiento,
  });
}
