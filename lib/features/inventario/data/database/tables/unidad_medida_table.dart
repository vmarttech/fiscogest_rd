import 'package:drift/drift.dart';

@DataClassName('UnidadMedidaData')
class UnidadesMedida extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text().unique()();
  TextColumn get abreviatura => text().nullable()();
  TextColumn get descripcion => text().nullable()();
  TextColumn get codigo => text().withDefault(const Constant(''))();
  RealColumn get factorABase => real().withDefault(const Constant(1.0))();
  BoolColumn get esBase => boolean().withDefault(const Constant(false))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get creadoEn => dateTime()();
  DateTimeColumn get actualizadoEn => dateTime().nullable()();
}
