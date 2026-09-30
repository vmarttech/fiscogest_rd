import 'package:drift/drift.dart';

class ConteosFisicos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombreConteo => text()();
  DateTimeColumn get fechaConteo => dateTime()();
  TextColumn get observaciones => text().nullable()();
  IntColumn get usuarioId => integer()();
  DateTimeColumn get fechaCreacion =>
      dateTime().withDefault(currentDateAndTime)();
  TextColumn get estado => text()();
}
