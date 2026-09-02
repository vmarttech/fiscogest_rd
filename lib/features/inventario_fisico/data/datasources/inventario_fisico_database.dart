import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

part 'inventario_fisico_database.g.dart';

// ✅ RENOMBRAMOS PARA COINCIDENCIA EXACTA CON EL RESTO DEL CÓDIGO
class ConteosFisicos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombreConteo => text()();
  DateTimeColumn get fechaConteo => dateTime()();
  TextColumn get observaciones => text().nullable()();
  IntColumn get usuarioId => integer()();
  DateTimeColumn get fechaCreacion =>
      dateTime().withDefault(currentDateAndTime)();
  TextColumn get estado => text().withDefault(const Constant('pendiente'))();
}

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
  TextColumn get estado => text().withDefault(const Constant('pendiente'))();
}

@DriftDatabase(tables: [ConteosFisicos, DiferenciasConteo])
class InventarioFisicoDatabase extends _$InventarioFisicoDatabase {
  InventarioFisicoDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'fiscogest.db'));
    return NativeDatabase(file);
  });
}
