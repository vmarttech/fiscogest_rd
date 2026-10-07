import 'package:drift/drift.dart';

@DataClassName('ImpuestoData')
class ImpuestosTable extends Table {
  @override
  String get tableName => 'impuestos';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get codigo => text().withDefault(const Constant(''))();
  TextColumn get nombre => text().unique()();
  RealColumn get porcentaje => real()();
  TextColumn get tipo => text().withDefault(const Constant('ITBIS'))();
  BoolColumn get esExento => boolean().withDefault(const Constant(false))();
  BoolColumn get esDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  TextColumn get descripcion => text().withDefault(const Constant(''))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get actualizadoEn => dateTime().nullable()();
}
