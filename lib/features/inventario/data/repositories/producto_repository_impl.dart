import '../../../../core/database/app_database.dart';
import '../../domain/entities/producto.dart';
import '../../domain/interfaces/i_producto_repository.dart';
import '../mappers/producto_mapper.dart';

class ProductoRepositoryImpl implements IProductoRepository {
  final AppDatabase _db;

  ProductoRepositoryImpl(this._db);

  @override
  Future<List<Producto>> obtenerProductos() async {
    final results = await _db.select(_db.productosTable).get();
    return results.map(ProductoDataMapper.toDomain).toList();
  }

  @override
  Future<Producto?> obtenerProductoPorId(int id) async {
    final query = _db.select(_db.productosTable)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return ProductoDataMapper.toDomain(row);
  }

  @override
  Future<int> guardarProducto(Producto producto) async {
    return await _db.into(_db.productosTable).insert(
      ProductoDataMapper.toCompanion(producto),
    );
  }

  @override
  Future<bool> actualizarProducto(Producto producto) async {
    if (producto.id == null) return false;
    final rowsAffected = await (_db.update(_db.productosTable)
      ..where((t) => t.id.equals(producto.id!))).write(
        ProductoDataMapper.toCompanion(producto),
      );
    return rowsAffected > 0;
  }

  @override
  Future<bool> eliminarProducto(int id) async {
    final rowsAffected = await (_db.delete(_db.productosTable)
      ..where((t) => t.id.equals(id))).go();
    return rowsAffected > 0;
  }
}