import 'package:drift/drift.dart';

@DataClassName('PlanillaData')
class PlanillasTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  /// Ej: 2026-11 | 2026-11-Q1 | 2026-11-Q2
  TextColumn get periodo => text()();
  /// mensual | quincena1 | quincena2
  TextColumn get tipoPeriodo => text().withDefault(const Constant('mensual'))();
  DateTimeColumn get fechaInicio => dateTime()();
  DateTimeColumn get fechaFin => dateTime()();
  /// borrador | cerrada | pagada
  TextColumn get estado => text().withDefault(const Constant('borrador'))();
  RealColumn get totalBruto => real().withDefault(const Constant(0.0))();
  RealColumn get totalNeto => real().withDefault(const Constant(0.0))();
  RealColumn get totalTssTrab => real().withDefault(const Constant(0.0))();
  RealColumn get totalIsr => real().withDefault(const Constant(0.0))();
  RealColumn get totalCostoEmpleador => real().withDefault(const Constant(0.0))();
  DateTimeColumn get fechaPago => dateTime().nullable()();
  TextColumn get notas => text().nullable()();
  DateTimeColumn get creadoEn => dateTime()();
  DateTimeColumn get actualizadoEn => dateTime().nullable()();
}
