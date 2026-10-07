import 'package:drift/drift.dart';

@DataClassName('CategoriaData')
class Categorias extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text().unique()();
  TextColumn get descripcion => text().nullable()();
  TextColumn get codigo => text().withDefault(const Constant(''))();
  IntColumn get padreId => integer().nullable()();
  RealColumn get itbisPorCiento => real().nullable()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get creadoEn => dateTime()();
  DateTimeColumn get actualizadoEn => dateTime().nullable()();
}
