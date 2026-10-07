import 'package:drift/drift.dart';

@DataClassName('AlmacenData')
class AlmacenesTable extends Table {
  @override
  String get tableName => 'almacenes';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get codigo => text()();
  TextColumn get nombre => text()();
  TextColumn get tipo => text().withDefault(const Constant('tienda'))();
  TextColumn get direccion => text().nullable()();
  TextColumn get telefono => text().nullable()();
  TextColumn get responsable => text().nullable()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get creadoEn =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get actualizadoEn => dateTime().nullable()();
}
