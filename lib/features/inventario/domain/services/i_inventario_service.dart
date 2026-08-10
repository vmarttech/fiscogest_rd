abstract class IInventarioService {
  Future<void> sumarStock(int productoId, double cantidad);
  Future<void> restarStock(int productoId, double cantidad);
}
