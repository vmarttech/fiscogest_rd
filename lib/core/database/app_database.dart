import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../features/clientes/data/dao/clientes_table.dart';
import '../../features/configuracion/data/dao/configuracion_table.dart';
import '../../features/inventario/data/dao/productos_table.dart';
import '../../features/inventario/data/dao/entradas_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [ClientesTable, ConfiguracionTable, ProductosTable, EntradasTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(entradasTable);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'fiscogest.sqlite'));
    return NativeDatabase(file);
  });
}
