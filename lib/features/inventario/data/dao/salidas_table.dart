import 'package:drift/drift.dart';

@DataClassName('SalidaData')
class SalidasTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productoId => integer().named('producto_id')();
  // ✅ CORREGIDO INTEGER → REAL
  RealColumn get cantidad => real()();
  TextColumn get motivo => text()();
  TextColumn get usuario => text()();
  IntColumn get fecha => integer()();
  // ✅ AGREGADO
  TextColumn get observacion => text().nullable()();
}
