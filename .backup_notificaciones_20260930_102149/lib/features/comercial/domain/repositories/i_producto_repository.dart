import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';

abstract class IProductoRepository {
  Future<void> actualizarCostoProducto({
    required int productoId,
    required double costoUnitario,
    required double cantidadAnterior,
    required double cantidadMovimiento,
  });

  Future<List<Producto>> obtenerProductos();

  Future<int> guardarProducto(Producto producto, int usuarioId);

  Future<void> actualizarProducto(Producto producto);

  Future<void> eliminarProducto(int id);
}
