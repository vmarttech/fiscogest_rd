import 'package:drift/drift.dart';

@DataClassName('UnidadMedidaData')
class UnidadesMedida extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text().unique()();
  TextColumn get abreviatura => text().nullable()();
  TextColumn get descripcion => text().nullable()();
  DateTimeColumn get creadoEn => dateTime()();
  DateTimeColumn get actualizadoEn => dateTime().nullable()();
}
