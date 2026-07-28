import 'package:drift/drift.dart';

class SalidasTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productoId => integer()();
  IntColumn get cantidad => integer()();
  TextColumn get motivo => text()();
  TextColumn get usuario => text()();
  DateTimeColumn get fecha => dateTime()();
}