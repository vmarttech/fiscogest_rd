import 'package:drift/drift.dart';

@DataClassName('PresentacionData')
class PresentacionesTable extends Table {
  @override
  String get tableName => 'presentaciones';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text().unique()();
  TextColumn get abreviatura => text().withDefault(const Constant(''))();
  TextColumn get codigo => text().withDefault(const Constant(''))();
  RealColumn get factorUnidades => real().withDefault(const Constant(1.0))();
  IntColumn get unidadMedidaId => integer().nullable()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get actualizadoEn => dateTime().nullable()();
}
