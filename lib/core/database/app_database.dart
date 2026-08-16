// ignore_for_file: experimental_member_use

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

import 'package:fiscogest_rd/features/inventario/data/dao/existencias_table.dart';

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
  ExistenciasTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  $CategoriasTable get categorias => super.categorias;

  @override
  $MarcasTable get marcas => super.marcas;

  @override
  $UnidadesMedidaTable get unidadesMedida => super.unidadesMedida;

  @override
  $ConteosFisicosTable get conteosFisicos => super.conteosFisicos;

  @override
  $DiferenciasConteoTable get diferenciasConteo => super.diferenciasConteo;

  @override
  $ExistenciasTableTable get existenciasTable => super.existenciasTable;

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async => await m.createAll(),
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) { await m.createTable(entradasTable); await m.createTable(salidasTable); }
          if (from < 4) { await m.createTable(categorias); await m.createTable(marcas); await m.createTable(unidadesMedida); }
          if (from < 5) { await m.createTable(kardexTable); }
          if (from < 6) { await m.createTable(ajusteInventarioTable); }
          if (from < 7) { await m.createTable(conteosFisicos); await m.createTable(diferenciasConteo); }
          if (from < 8) { await m.createTable(existenciasTable); }
          if (from >= 8 && from < 9) {
            await m.alterTable(TableMigration(productosTable, newColumns: [productosTable.stockMaximo]));
            await m.alterTable(TableMigration(entradasTable, newColumns: [entradasTable.costoUnitario, entradasTable.observacion]));
            await m.alterTable(TableMigration(salidasTable, newColumns: [salidasTable.observacion]));
            await m.alterTable(TableMigration(existenciasTable, newColumns: [existenciasTable.ubicacion, existenciasTable.fechaActualizacion]));
            await m.alterTable(TableMigration(kardexTable));
            await m.alterTable(TableMigration(ajusteInventarioTable));
            await m.alterTable(TableMigration(diferenciasConteo));
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final carpetaBase = await getApplicationDocumentsDirectory();
    final archivoDb = File(p.join(carpetaBase.path, 'fiscogest.sqlite'));
    return NativeDatabase(archivoDb);
  });
}
