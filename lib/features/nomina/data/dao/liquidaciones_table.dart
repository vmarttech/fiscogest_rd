import 'package:drift/drift.dart';

@DataClassName('LiquidacionData')
class LiquidacionesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get empleadoId => integer()();
  TextColumn get nombreEmpleado => text()();
  DateTimeColumn get fechaIngreso => dateTime()();
  DateTimeColumn get fechaSalida => dateTime()();
  RealColumn get salarioMensual => real()();
  RealColumn get aniosServicio => real()();
  RealColumn get montoPreaviso => real().withDefault(const Constant(0.0))();
  RealColumn get montoCesantia => real().withDefault(const Constant(0.0))();
  RealColumn get montoVacaciones => real().withDefault(const Constant(0.0))();
  RealColumn get montoRegalia => real().withDefault(const Constant(0.0))();
  RealColumn get total => real().withDefault(const Constant(0.0))();
  TextColumn get notas => text().nullable()();
  DateTimeColumn get creadoEn => dateTime()();
}
