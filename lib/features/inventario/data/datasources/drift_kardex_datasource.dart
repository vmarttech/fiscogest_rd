import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';

class DriftKardexDatasource {
  DriftKardexDatasource(this._db);
  final AppDatabase _db;

  Future<void> insertar(KardexTableCompanion companion) async {
    await _db.into(_db.kardexTable).insert(companion);
  }

  Future<List<KardexData>> obtenerHistorialPorProducto(int idProducto) async {
    return await (_db.select(_db.kardexTable)
          ..where((t) => t.productoId.equals(idProducto))
          ..orderBy([(t) => OrderingTerm(expression: t.fechaMovimiento, mode: OrderingMode.desc)]))
        .get();
  }

  Future<List<KardexData>> obtenerTodoElHistorial({DateTime? desde, DateTime? hasta}) async {
    final query = _db.select(_db.kardexTable);
    if (desde != null) {
      query.where((t) => t.fechaMovimiento.isBiggerOrEqualValue(desde.millisecondsSinceEpoch));
    }
    if (hasta != null) {
      query.where((t) => t.fechaMovimiento.isSmallerOrEqualValue(hasta.millisecondsSinceEpoch));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.fechaMovimiento)]);
    return await query.get();
  }

  // ✅ Método faltante, elimina error repositorio
  Future<KardexData?> obtenerUltimo(int idProducto) async {
    return await (_db.select(_db.kardexTable)
          ..where((t) => t.productoId.equals(idProducto))
          ..orderBy([(t) => OrderingTerm.desc(t.fechaMovimiento)])
          ..limit(1))
        .getSingleOrNull();
  }
}
