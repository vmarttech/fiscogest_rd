import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/contabilidad/data/dao/asientos_table.dart';
import 'package:fiscogest_rd/core/contabilidad/data/dao/plan_cuentas_table.dart';

class LineasAsientoTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get asientoId => integer().references(AsientosTable, #id)();
  IntColumn get cuentaId => integer().references(PlanCuentasTable, #id)();
  RealColumn get debe => real().withDefault(const Constant(0.0))();
  RealColumn get haber => real().withDefault(const Constant(0.0))();
  TextColumn get conceptoLinea => text().nullable()();
}
