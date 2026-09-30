import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';

abstract class IProductoRepository {
  Future<List<Producto>> obtenerProductos();
  Future<Producto?> obtenerProductoPorId(int id);
  Future<Producto?> obtenerProductoPorCodigo(String codigo);
  Future<int> guardarProducto(Producto producto, int idUsuario);
  Future<bool> actualizarProducto(Producto producto);
  Future<bool> eliminarProducto(int id);
}
