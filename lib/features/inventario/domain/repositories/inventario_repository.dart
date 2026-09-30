/// Contrato abstracto | Capa Dominio | Sin dependencias externas
/// Define operaciones generales de gestión de existencias
abstract class InventarioRepository {
  /// Actualizar cantidad en existencia por identificador de producto
  Future<void> actualizarStock(int idProducto, double nuevoValor);

  /// Consultar cantidad disponible actual
  Future<double?> obtenerStockActual(int idProducto);

  /// Validar si hay cantidad suficiente disponible
  Future<bool> hayStockSuficiente(int idProducto, double cantidadRequerida);

  /// Aumentar existencias de un producto tras entrada (compra/ajuste)
  Future<void> aumentarExistencias({
    required int productoId,
    required double cantidad,
  });

  /// Descontar existencias de un producto tras salida (venta/ajuste)
  Future<void> descontarExistencias({
    required int productoId,
    required double cantidad,
  });
}
