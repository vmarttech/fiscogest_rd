import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:fiscogest_rd/features/clientes/data/dao/clientes_table.dart';
import 'package:fiscogest_rd/features/configuracion/data/dao/configuracion_table.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/productos_table.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/entradas_table.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/salidas_table.dart';
import 'package:fiscogest_rd/features/inventario/data/database/tables/categoria_table.dart';
import 'package:fiscogest_rd/features/inventario/data/database/tables/marca_table.dart';
import 'package:fiscogest_rd/features/inventario/data/database/tables/unidad_medida_table.dart';
import 'package:fiscogest_rd/features/inventario/data/database/tables/kardex_table.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/data/datasources/ajuste_inventario_database.dart';
import 'package:fiscogest_rd/features/inventario_fisico/data/database/tables/conteo_fisico_table.dart';
import 'package:fiscogest_rd/features/inventario_fisico/data/database/tables/diferencia_conteo_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  ClientesTable,
  ConfiguracionTable,
  ProductosTable,
  EntradasTable,
  SalidasTable,
  Categorias,
  Marcas,
  UnidadesMedida,
  KardexTable,
  AjusteInventarioTable,
  ConteosFisicos,
  DiferenciasConteo,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async => await m.createAll(),
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(entradasTable);
            await m.createTable(salidasTable);
          }
          if (from < 4) {
            await m.createTable(categorias);
            await m.createTable(marcas);
            await m.createTable(unidadesMedida);
          }
          if (from < 5) {
            await m.createTable(kardexTable);
          }
          if (from < 6) {
            await m.createTable(ajusteInventarioTable);
          }
          if (from < 7) {
            await m.createTable(conteosFisicos);
            await m.createTable(diferenciasConteo);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // ✅ Ruta automática válida en ANDROID, iOS, Windows, Linux y macOS
    final carpetaBase = await getApplicationDocumentsDirectory();
    final archivoDb = File(p.join(carpetaBase.path, 'fiscogest.sqlite'));
    return NativeDatabase(archivoDb);
  });
}
