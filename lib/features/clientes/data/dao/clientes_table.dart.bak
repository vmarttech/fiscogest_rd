import 'package:drift/drift.dart';

class ClientesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get codigo => text().unique()();
  TextColumn get nombre => text()();
  TextColumn get rncCedula => text()();
  TextColumn get telefono => text()();
  TextColumn get correo => text()();
  TextColumn get direccion => text()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
}