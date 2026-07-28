import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

part 'inventario_database.g.dart';

class InventarioTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get codigo => text().unique()();
  TextColumn get nombre => text()();
  RealColumn get precioCompra => real()();
  RealColumn get precioVenta => real()();
  RealColumn get stockActual => real().withDefault(const Constant(0))();
  RealColumn get stockMinimo => real().withDefault(const Constant(0))();
  IntColumn get categoriaId => integer()();
  IntColumn get marcaId => integer()();
  IntColumn get unidadId => integer()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get fechaCreacion => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get fechaActualizacion => dateTime().nullable()();
}

@DriftDatabase(tables: [InventarioTable])
class InventarioDatabase extends _$InventarioDatabase {
  InventarioDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'inventario.db'));
    return NativeDatabase(file);
  });
}
