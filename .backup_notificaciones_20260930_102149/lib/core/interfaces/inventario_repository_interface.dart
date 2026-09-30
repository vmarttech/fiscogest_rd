import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';

abstract class InventarioRepositoryInterface {
  Future<List<Producto>> listarProductos();
  Future<Producto?> obtenerProductoPorId(int id);
  Future<Producto?> obtenerProductoPorCodigo(String codigo);
  Future<void> crearProducto(Producto producto);
  Future<void> actualizarProducto(Producto producto);
  Future<void> eliminarProducto(int id);
  Future<void> actualizarStock(int productoId, double nuevoStock);
}
