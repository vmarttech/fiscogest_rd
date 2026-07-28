import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';

abstract class IProductoRepository {
  Future<List<Producto>> obtenerProductos();
  Future<Producto?> obtenerProductoPorId(int id);
  Future<int> guardarProducto(Producto producto);
  Future<bool> actualizarProducto(Producto producto);
  Future<bool> eliminarProducto(int id);
}
