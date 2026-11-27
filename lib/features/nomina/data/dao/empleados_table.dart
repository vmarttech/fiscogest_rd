import 'package:drift/drift.dart';

@DataClassName('EmpleadoData')
class EmpleadosTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();
  TextColumn get apellido => text()();
  TextColumn get cedula => text().nullable()();
  TextColumn get telefono => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get cargo => text().nullable()();
  RealColumn get salarioBase => real().withDefault(const Constant(0.0))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get fechaIngreso => dateTime().nullable()();
  TextColumn get banco => text().nullable()();
  TextColumn get tipoCuenta => text().nullable()();
  TextColumn get numeroCuenta => text().nullable()();
  TextColumn get formaPago => text().withDefault(const Constant('transferencia'))();
  TextColumn get notas => text().nullable()();
  DateTimeColumn get creadoEn => dateTime()();
  DateTimeColumn get actualizadoEn => dateTime().nullable()();
}
