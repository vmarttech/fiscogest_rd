import 'package:drift/drift.dart';

class EntradasTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productoId => integer()();
  RealColumn get cantidad => real()();
  TextColumn get motivo => text()();
  TextColumn get usuario => text()();
  DateTimeColumn get fecha => dateTime()();
}
