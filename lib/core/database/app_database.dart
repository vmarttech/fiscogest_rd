import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
// ignore_for_file: experimental_member_use
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/riverpod.dart';
// Tablas existentes
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
// NUEVAS: Tablas base Fase 4
import 'package:fiscogest_rd/features/proveedores/data/dao/proveedores_table.dart';
import 'package:fiscogest_rd/features/seguridad/data/dao/usuarios_table.dart';
// NUEVAS: Tablas Fase 4 - Módulo Comercial
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_detalle_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cotizaciones_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cotizaciones_detalle_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_detalle_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/devoluciones_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/devoluciones_detalle_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cobros_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_pagar_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/descuentos_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ofertas_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/kardex_comercial_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/caja_movimientos_table.dart';
// NUEVAS: Tablas Compras - Etapa 4.1
import 'package:fiscogest_rd/features/comercial/data/dao/compras_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/detalle_compra_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    // Tablas existentes
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
    // NUEVAS: Tablas base
    ProveedoresTable,
    UsuariosTable,
    // NUEVAS: Fase 4 - Ventas
    VentasTable,
    VentasDetalleTable,
    // NUEVAS: Fase 4 - Cotizaciones
    CotizacionesTable,
    CotizacionesDetalleTable,
    // NUEVAS: Fase 4 - Apartados
    ApartadosTable,
    ApartadosDetalleTable,
    // NUEVAS: Fase 4 - Devoluciones
    DevolucionesTable,
    DevolucionesDetalleTable,
    // NUEVAS: Fase 4 - Cuentas por Cobrar
    CuentasCobrarTable,
    CobrosTable,
    // NUEVAS: Fase 4 - Cuentas por Pagar
    CuentasPagarTable,
    // NUEVAS: Fase 4 - Configuración comercial
    DescuentosTable,
    OfertasTable,
    // NUEVAS: Fase 4 - Integración en cascada
    KardexComercialTable,
    CajaMovimientosTable,
    // NUEVAS: Etapa 4.1 - COMPRAS
    ComprasTable,
    DetalleCompraTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  factory AppDatabase() => _instance;
  AppDatabase._internal() : super(_openConnection());
  // ✅ SINGLETON: UNA SOLA INSTANCIA EN TODA LA APP
  static final AppDatabase _instance = AppDatabase._internal();
  // ✅ VERSIÓN ACTUALIZADA: 12 → 13
  @override
  int get schemaVersion => 14;

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
      if (from < 8) {
        await m.createTable(existenciasTable);
      }
      if (from >= 8 && from < 9) {
        await m.alterTable(
          TableMigration(
            productosTable,
            newColumns: [productosTable.stockMaximo],
          ),
        );
        await m.alterTable(
          TableMigration(
            entradasTable,
            newColumns: [
              entradasTable.costoUnitario,
              entradasTable.observacion,
            ],
          ),
        );
        await m.alterTable(
          TableMigration(salidasTable, newColumns: [salidasTable.observacion]),
        );
        await m.alterTable(
          TableMigration(
            existenciasTable,
            newColumns: [
              existenciasTable.ubicacion,
              existenciasTable.fechaActualizacion,
            ],
          ),
        );
        await m.alterTable(TableMigration(ajusteInventarioTable));
        await m.alterTable(TableMigration(diferenciasConteo));
      }
      if (from < 10) {
        await m.createTable(proveedoresTable);
        await m.createTable(usuariosTable);
        await m.createTable(ventasTable);
        await m.createTable(ventasDetalleTable);
        await m.createTable(cotizacionesTable);
        await m.createTable(cotizacionesDetalleTable);
        await m.createTable(apartadosTable);
        await m.createTable(apartadosDetalleTable);
        await m.createTable(devolucionesTable);
        await m.createTable(devolucionesDetalleTable);
        await m.createTable(cuentasCobrarTable);
        await m.createTable(cobrosTable);
        await m.createTable(cuentasPagarTable);
        await m.createTable(descuentosTable);
        await m.createTable(ofertasTable);
        await m.createTable(kardexComercialTable);
        await m.createTable(cajaMovimientosTable);
      }
      if (from < 11) {
        await m.createTable(comprasTable);
        await m.createTable(detalleCompraTable);
      }
      if (from < 12) {
        await m.alterTable(
          TableMigration(
            clientesTable,
            newColumns: [clientesTable.saldoPendiente],
          ),
        );
      }
      // ✅ MIGRACIÓN VERSIÓN 12 → 13: Agregar columnas nuevas a productos
      if (from < 13) {
        await m.alterTable(
          TableMigration(
            productosTable,
            newColumns: [
              productosTable.gastosAsociados,
              productosTable.margenGanancia,
              productosTable.precioMinimo,
              productosTable.precioMayorista,
              productosTable.precioEspecial,
            ],
          ),
        );
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final carpetaBase = await getApplicationDocumentsDirectory();
    final archivoDb = File(p.join(carpetaBase.path, 'fiscogest_rd.sqlite'));
    return NativeDatabase.createInBackground(archivoDb);
  });
}

// ✅ PROVIDER GLOBAL: ÚNICA INSTANCIA COMPARTIDA
final appDatabaseProvider = Provider((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
