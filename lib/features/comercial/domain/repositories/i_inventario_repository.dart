/// Contrato abstracto para operaciones de inventario.
abstract class IInventarioRepository {
  /// Incrementa las existencias de un producto tras ingreso por compra.
  Future<void> aumentarExistencias({
    required String productoId,
    required double cantidad,
  });

  /// Reduce existencias tras venta o salida.
  Future<void> descontarExistencias({
    required String productoId,
    required double cantidad,
  });
}
