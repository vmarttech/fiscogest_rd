import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/services/i_inventario_service.dart';

class InventarioServiceImpl implements IInventarioService {
  InventarioServiceImpl(this.db);

  final AppDatabase db;

  @override
  Future<void> sumarStock(int productoId, double cantidad) async {
    final producto = await (db.select(
      db.productosTable,
    )..where((p) => p.id.equals(productoId))).getSingle();
    final stockActual = producto.stock ?? 0.0;
    await db
        .update(db.productosTable)
        .replace(producto.copyWith(stock: Value(stockActual + cantidad)));
  }

  @override
  Future<void> restarStock(int productoId, double cantidad) async {
    final producto = await (db.select(
      db.productosTable,
    )..where((p) => p.id.equals(productoId))).getSingle();
    final stockActual = producto.stock ?? 0.0;
    await db
        .update(db.productosTable)
        .replace(producto.copyWith(stock: Value(stockActual - cantidad)));
  }
}
