import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/repositories/inventario_repository.dart';
/// Implementación concreta | Capa Datos | Cumple contrato InventarioRepository
class InventarioRepositoryImpl implements InventarioRepository {
  InventarioRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<void> actualizarStock(int idProducto, double nuevoValor) async {
    await (_db.update(_db.productosTable)
          ..where((fila) => fila.id.equals(idProducto)))
        .write(ProductosTableCompanion(stock: Value(nuevoValor)));
  }

  @override
  Future<double?> obtenerStockActual(int idProducto) async {
    final registro =
        await (_db.select(_db.productosTable)
              ..where((fila) => fila.id.equals(idProducto))
              ..limit(1))
            .getSingleOrNull();
    return registro?.stock;
  }

  @override
  Future<bool> hayStockSuficiente(
    int idProducto,
    double cantidadRequerida,
  ) async {
    final actual = await obtenerStockActual(idProducto) ?? 0.0;
    return actual >= cantidadRequerida;
  }

  @override
  Future<void> aumentarExistencias({
    required int productoId,
    required double cantidad,
  }) async {
    final actual = await obtenerStockActual(productoId) ?? 0.0;
    final nuevoStock = actual + cantidad;
    await actualizarStock(productoId, nuevoStock);
  }

  @override
  Future<void> descontarExistencias({
    required int productoId,
    required double cantidad,
  }) async {
    final actual = await obtenerStockActual(productoId) ?? 0.0;
    if (actual < cantidad) {
      throw StateError('Stock insuficiente: $actual < $cantidad');
    }
    final nuevoStock = actual - cantidad;
    await actualizarStock(productoId, nuevoStock);
  }
}
