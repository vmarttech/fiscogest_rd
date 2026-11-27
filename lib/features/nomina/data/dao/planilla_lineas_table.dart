import 'package:drift/drift.dart';

@DataClassName('PlanillaLineaData')
class PlanillaLineasTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planillaId => integer()();
  IntColumn get empleadoId => integer()();
  TextColumn get nombreEmpleado => text()();
  TextColumn get cargo => text().nullable()();
  RealColumn get salarioBase => real().withDefault(const Constant(0.0))();
  RealColumn get montoBruto => real().withDefault(const Constant(0.0))();
  // Trabajador
  RealColumn get tssAfp => real().withDefault(const Constant(0.0))();
  RealColumn get tssSfs => real().withDefault(const Constant(0.0))();
  RealColumn get isr => real().withDefault(const Constant(0.0))();
  RealColumn get montoNeto => real().withDefault(const Constant(0.0))();
  // Empleador (congelado al calcular la línea)
  RealColumn get afpPatronal => real().withDefault(const Constant(0.0))();
  RealColumn get sfsPatronal => real().withDefault(const Constant(0.0))();
  RealColumn get srlPatronal => real().withDefault(const Constant(0.0))();
  RealColumn get fondoSolidaridad => real().withDefault(const Constant(0.0))();
  RealColumn get infotep => real().withDefault(const Constant(0.0))();
  TextColumn get notas => text().nullable()();
}
