import 'package:drift/drift.dart';

class GastosTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get fecha => dateTime()();
  TextColumn get categoria => text().withDefault(const Constant('General'))();
  TextColumn get descripcion => text()();
  RealColumn get monto => real()();
  TextColumn get formaPago => text().withDefault(const Constant('efectivo'))();
  TextColumn get notas => text().nullable()();
  DateTimeColumn get creadoEn => dateTime()();
  DateTimeColumn get actualizadoEn => dateTime().nullable()();
}
