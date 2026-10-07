import 'package:drift/drift.dart';

@DataClassName('MarcaData')
class Marcas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text().unique()();
  TextColumn get descripcion => text().nullable()();
  TextColumn get codigo => text().withDefault(const Constant(''))();
  TextColumn get fabricante => text().nullable()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get creadoEn => dateTime()();
  DateTimeColumn get actualizadoEn => dateTime().nullable()();
}
