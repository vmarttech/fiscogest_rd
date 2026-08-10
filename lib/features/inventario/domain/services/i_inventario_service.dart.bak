abstract class IInventarioService {
  Future<void> sumarStock(int productoId, double cantidad);
  Future<void> restarStock(int productoId, double cantidad);

  // ===== Métodos agregados FASE3: Validación, Stock Mín/Máx y Alertas =====
  Future<double> obtenerStockActual(int productoId);
  Future<bool> esStockSuficiente(int productoId, double cantidad);
  Future<(double min, double max)> obtenerLimitesStock(int productoId);
  Future<List<int>> obtenerProductosBajosDeStock();
  Future<List<int>> obtenerProductosAgotados();
}
