import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';

class StockAlmacenDao {
  StockAlmacenDao(this._db);
  final AppDatabase _db;

  Future<double> cantidad(int productoId, int almacenId) async {
    final r = await (_db.select(_db.stockAlmacenTable)
          ..where(
            (t) =>
                t.productoId.equals(productoId) & t.almacenId.equals(almacenId),
          ))
        .getSingleOrNull();
    return r?.cantidad ?? 0;
  }

  Future<void> setCantidad(int productoId, int almacenId, double cant) async {
    final existente = await (_db.select(_db.stockAlmacenTable)
          ..where(
            (t) =>
                t.productoId.equals(productoId) & t.almacenId.equals(almacenId),
          ))
        .getSingleOrNull();
    if (existente == null) {
      await _db.into(_db.stockAlmacenTable).insert(
            StockAlmacenTableCompanion.insert(
              productoId: productoId,
              almacenId: almacenId,
              cantidad: Value(cant),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      final otraVez = await (_db.select(_db.stockAlmacenTable)
            ..where(
              (t) =>
                  t.productoId.equals(productoId) &
                  t.almacenId.equals(almacenId),
            ))
          .getSingleOrNull();
      if (otraVez != null && (otraVez.cantidad - cant).abs() > 1e-9) {
        await (_db.update(_db.stockAlmacenTable)
              ..where((t) => t.id.equals(otraVez.id)))
            .write(StockAlmacenTableCompanion(cantidad: Value(cant)));
      }
    } else {
      await (_db.update(_db.stockAlmacenTable)
            ..where((t) => t.id.equals(existente.id)))
          .write(StockAlmacenTableCompanion(cantidad: Value(cant)));
    }
  }

  /// Copia stock global → almacén principal solo para SKUs que aún no tienen fila.
  Future<void> sembrarDesdeProductos() async {
    await _db.transaction(() async {
      final almacenes = await _db.select(_db.almacenesTable).get();
      if (almacenes.isEmpty) return;
      final principal = almacenes.firstWhere(
        (a) => a.tipo == 'principal',
        orElse: () => almacenes.first,
      );
      final productos = await _db.select(_db.productosTable).get();
      for (final p in productos) {
        double cant = 0;
        try {
          cant = (p.stock as num?)?.toDouble() ?? 0;
        } catch (_) {
          cant = 0;
        }
        await _db.into(_db.stockAlmacenTable).insert(
              StockAlmacenTableCompanion.insert(
                productoId: p.id,
                almacenId: principal.id,
                cantidad: Value(cant),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }
}
