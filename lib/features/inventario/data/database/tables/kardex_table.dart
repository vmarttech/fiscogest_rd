import 'package:drift/drift.dart';

class KardexTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get idProducto => integer()();
  TextColumn get tipoMovimiento => text()();
  RealColumn get cantidad => real()();
  RealColumn get saldoAnterior => real()();
  RealColumn get saldoNuevo => real()();
  RealColumn get costoUnitario => real()();
  RealColumn get totalMovimiento => real()();
  IntColumn get referenciaId => integer().nullable()();
  TextColumn get documentoReferencia => text().nullable()();
  TextColumn get motivo => text()();
  IntColumn get usuarioId => integer()();
  DateTimeColumn get fechaMovimiento => dateTime().nullable().withDefault(currentDateAndTime)();
  TextColumn get observacion => text().nullable()();
}
