import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_inventario_repository.dart';

class InventarioRepositoryImpl implements IInventarioRepository {
  InventarioRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<double?> obtenerStockActual(int productoId) async {
    final registro =
        await (_db.select(_db.productosTable)
              ..where((fila) => fila.id.equals(productoId))
              ..limit(1))
            .getSingleOrNull();
    return registro?.stock;
  }

  @override
  Future<void> aumentarExistencias({
    required int productoId,
    required double cantidad,
  }) async {
    final registro =
        await (_db.select(_db.productosTable)
              ..where((fila) => fila.id.equals(productoId))
              ..limit(1))
            .getSingleOrNull();
    final actual = registro?.stock ?? 0.0;
    final nuevoStock = actual + cantidad;
    await (_db.update(_db.productosTable)
          ..where((fila) => fila.id.equals(productoId)))
        .write(ProductosTableCompanion(stock: Value(nuevoStock)));
  }

  @override
  Future<void> descontarExistencias({
    required int productoId,
    required double cantidad,
  }) async {
    final registro =
        await (_db.select(_db.productosTable)
              ..where((fila) => fila.id.equals(productoId))
              ..limit(1))
            .getSingleOrNull();
    final actual = registro?.stock ?? 0.0;
    if (actual < cantidad) {
      throw StateError('Existencias insuficientes para producto: $productoId');
    }
    final nuevoStock = actual - cantidad;
    await (_db.update(_db.productosTable)
          ..where((fila) => fila.id.equals(productoId)))
        .write(ProductosTableCompanion(stock: Value(nuevoStock)));
  }
}
