import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/productos_table.dart';
part 'productos_dao.g.dart';

@DriftAccessor(tables: [ProductosTable])
class ProductosDao extends DatabaseAccessor<AppDatabase> with _$ProductosDaoMixin {
  ProductosDao(AppDatabase db) : super(db);

  Future<bool> descontarStock(int productoId, double cantidad) async {
    final producto = await (select(productosTable)
      ..where((t) => t.id.equals(productoId)))
      .getSingleOrNull();
    if (producto == null) return false;
    final stockActual = producto.stock ?? 0.0;
    final nuevoStock = stockActual - cantidad;
    final filasAfectadas = await (update(productosTable)
      ..where((t) => t.id.equals(productoId)))
      .write(ProductosTableCompanion(stock: Value(nuevoStock)));
    return filasAfectadas > 0;
  }

  Future<double?> obtenerStock(int productoId) async {
    final producto = await (select(productosTable)
      ..where((t) => t.id.equals(productoId)))
      .getSingleOrNull();
    return producto?.stock;
  }

  Future<ProductoData?> obtenerPorId(int productoId) async {
    return await (select(productosTable)
      ..where((t) => t.id.equals(productoId)))
      .getSingleOrNull();
  }

  Future<List<ProductoData>> buscarPorNombre(String nombre) =>
      (select(productosTable)
        ..where((t) => t.nombre.lower().like('%${nombre.toLowerCase()}%'))
      ).get();
}
