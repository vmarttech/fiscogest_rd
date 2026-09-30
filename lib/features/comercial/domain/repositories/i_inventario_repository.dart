/// Contrato abstracto para operaciones de inventario.
abstract class IInventarioRepository {
  /// Incrementa las existencias de un producto tras ingreso por compra.
  Future<void> aumentarExistencias({
    required int productoId,
    required double cantidad,
  });

  /// Reduce existencias tras venta o salida.
  Future<void> descontarExistencias({
    required int productoId,
    required double cantidad,
  });

  /// Consultar existencias actuales de un producto.
  Future<double?> obtenerStockActual(int productoId);
}
