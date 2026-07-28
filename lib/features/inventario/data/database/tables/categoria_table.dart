import 'package:drift/drift.dart';

@DataClassName('CategoriaData')
class Categorias extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text().unique()();
  TextColumn get descripcion => text().nullable()();
  DateTimeColumn get creadoEn => dateTime()();
  DateTimeColumn get actualizadoEn => dateTime().nullable()();
}
