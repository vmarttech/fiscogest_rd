import 'package:drift/drift.dart';

class AjusteInventarioTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get idProducto => integer()();
  TextColumn get tipoAjuste => text().withLength(min: 1, max: 20)();
  RealColumn get cantidad => real()();
  TextColumn get motivo => text()();
  TextColumn get observaciones => text().nullable()();
  IntColumn get usuarioId => integer()();
  DateTimeColumn get fechaCreacion => dateTime().nullable().withDefault(currentDateAndTime)();
}
