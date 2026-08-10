import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/core/interfaces/inventario_repository_interface.dart';
import 'package:fiscogest_rd/features/inventario/data/mappers/producto_mapper.dart';

class InventarioRepositoryImpl implements InventarioRepositoryInterface {

  InventarioRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<List<Producto>> listarProductos() async {
    final datos = await _db.select(_db.productosTable).get();
    return datos.map((d) => ProductoDataMapper.toDomain(d)).toList();
  }

  @override
  Future<Producto?> obtenerProductoPorId(int id) async {
    final query = _db.select(_db.productosTable)..where((p) => p.id.equals(id));
    final dato = await query.getSingleOrNull();
    if (dato == null) return null;
    return ProductoDataMapper.toDomain(dato);
  }

  @override
  Future<Producto?> obtenerProductoPorCodigo(String codigo) async {
    final query = _db.select(_db.productosTable)..where((p) => p.codigo.equals(codigo));
    final dato = await query.getSingleOrNull();
    if (dato == null) return null;
    return ProductoDataMapper.toDomain(dato);
  }

  @override
  Future<void> crearProducto(Producto producto) async {
    final companion = ProductoDataMapper.toCompanion(producto);
    await _db.into(_db.productosTable).insert(companion);
  }

  @override
  Future<void> actualizarProducto(Producto producto) async {
    final companion = ProductoDataMapper.toCompanion(producto);
    await (_db.update(_db.productosTable)
      ..where((p) => p.id.equals(producto.id!)))
      .write(companion);
  }

  @override
  Future<void> eliminarProducto(int id) async {
    await (_db.delete(_db.productosTable)..where((p) => p.id.equals(id))).go();
  }

  @override
  Future<void> actualizarStock(int productoId, double nuevoStock) async {
    await (_db.update(_db.productosTable)
      ..where((p) => p.id.equals(productoId)))
      .write(ProductosTableCompanion(
        stock: Value(nuevoStock),
      ));
  }
}
