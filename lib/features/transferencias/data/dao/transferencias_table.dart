import 'package:drift/drift.dart';

@DataClassName('TransferenciaData')
class TransferenciasTable extends Table {
  @override
  String get tableName => 'transferencias';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get almacenOrigenId => integer()();
  IntColumn get almacenDestinoId => integer()();
  IntColumn get productoId => integer()();
  RealColumn get cantidad => real()();
  TextColumn get nota => text().nullable()();
  DateTimeColumn get fecha => dateTime().withDefault(currentDateAndTime)();
  TextColumn get estado => text().withDefault(const Constant('registrada'))();
}
