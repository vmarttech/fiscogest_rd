import 'package:drift/drift.dart';

class DiferenciasConteo extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conteoId => integer()();
  IntColumn get productoId => integer()();
  TextColumn get codigoProducto => text()();
  TextColumn get nombreProducto => text()();
  RealColumn get stockSistema => real()();
  RealColumn get stockFisico => real()();
  RealColumn get diferencia => real()();
  TextColumn get motivo => text().nullable()();
  TextColumn get estado => text()();
}
