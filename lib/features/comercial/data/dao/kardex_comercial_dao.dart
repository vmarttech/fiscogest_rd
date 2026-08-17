import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/kardex_comercial_table.dart';

part 'kardex_comercial_dao.g.dart';

@DriftAccessor(tables: [KardexComercialTable])
class KardexComercialDao extends DatabaseAccessor<AppDatabase> with _$KardexComercialDaoMixin {
  KardexComercialDao(super.db);

  Future<List<KardexComercialData>> obtenerTodos() => select(kardexComercialTable).get();

  Future<List<KardexComercialData>> obtenerPorProducto(int productoId) =>
      (select(kardexComercialTable)
        ..where((t) => t.productoId.equals(productoId))
        ..orderBy([(t) => OrderingTerm(expression: t.fecha, mode: OrderingMode.desc)])
      ).get();

  Future<List<KardexComercialData>> obtenerPorReferencia(String tipo, int id) =>
      (select(kardexComercialTable)
        ..where((t) => t.referenciaTipo.equals(tipo))
        ..where((t) => t.referenciaId.equals(id))
      ).get();

  Future<int> registrarMovimiento(KardexComercialTableCompanion movimiento) =>
      into(kardexComercialTable).insert(movimiento);

  Future<void> registrarMovimientosBatch(List<KardexComercialTableCompanion> movimientos) =>
      batch((batch) => batch.insertAll(kardexComercialTable, movimientos));
}
