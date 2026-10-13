import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
// ignore_for_file: experimental_member_use
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/riverpod.dart';
import 'package:fiscogest_rd/core/database/migrations/migracion_002_agregar_campos_productos.dart';
import 'package:fiscogest_rd/features/clientes/data/dao/clientes_table.dart';
import 'package:fiscogest_rd/features/almacenes/data/dao/almacenes_table.dart';
import 'package:fiscogest_rd/features/presentaciones/data/dao/presentaciones_table.dart';
import 'package:fiscogest_rd/features/impuestos/data/dao/impuestos_table.dart';
import 'package:fiscogest_rd/features/transferencias/data/dao/transferencias_table.dart';
import 'package:fiscogest_rd/features/almacenes/data/dao/stock_almacen_table.dart';
import 'package:fiscogest_rd/features/configuracion/data/dao/configuracion_table.dart';
import 'package:fiscogest_rd/features/licencias/data/dao/licencias_table.dart';
import 'package:fiscogest_rd/features/licencias/data/dao/pedidos_licencia_table.dart';
import 'package:fiscogest_rd/features/licencias/data/dao/dispositivos_licencia_table.dart';
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
import 'package:fiscogest_rd/features/proveedores/data/dao/proveedores_table.dart';
import 'package:fiscogest_rd/features/seguridad/data/dao/usuarios_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_detalle_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cotizaciones_table.dart';
import 'package:fiscogest_rd/features/ventas/data/dao/fios_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cotizaciones_detalle_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_detalle_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/devoluciones_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/devoluciones_detalle_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuotas_cuenta_table.dart';
import 'package:fiscogest_rd/features/creditos/data/dao/parametros_credito_table.dart';
import 'package:fiscogest_rd/features/creditos/data/dao/referencias_credito_table.dart';
import 'package:fiscogest_rd/features/creditos/data/dao/solicitudes_credito_table.dart';

import 'package:fiscogest_rd/features/comercial/data/dao/cobros_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_pagar_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/pagos_proveedor_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/descuentos_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ofertas_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/kardex_comercial_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/caja_movimientos_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/caja_sesiones_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/compras_table.dart';
import 'package:fiscogest_rd/features/gastos/data/dao/gastos_table.dart';
import 'package:fiscogest_rd/features/e_cf/data/dao/ecfe_tables.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/detalle_compra_table.dart';
import 'package:fiscogest_rd/features/facturacion/data/dao/secuencias_ncf_table.dart';
import 'package:fiscogest_rd/features/facturacion/data/dao/notas_credito_table.dart';
part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    LicenciasTable,
    PedidosLicenciaTable,
    DispositivosLicenciaTable,
    NotasCreditoTable,
    SecuenciasNcfTable,
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
    ProveedoresTable,
    UsuariosTable,
    VentasTable,
    VentasDetalleTable,
    CotizacionesTable,
    CotizacionesDetalleTable,
    ApartadosTable,
    ApartadosDetalleTable,
    DevolucionesTable,
    DevolucionesDetalleTable,
    CuentasCobrarTable,
    ParametrosCreditoTable,
    SolicitudesCreditoTable,
    ReferenciasCreditoTable,
    CobrosTable,
    CuotasCuentaTable,
    CuentasPagarTable,
    PagosProveedorTable,
    DescuentosTable,
    OfertasTable,
    KardexComercialTable,
    CajaMovimientosTable,
    CajaSesionesTable,
    ComprasTable,
    GastosTable,
    EcfeConfigTable,
    EcfeDocumentosTable,
    EcfeEventosTable,
    EcfeSecuenciasTable,
    EcfeSpecVersionTable,
    DetalleCompraTable,
    FiosTable,
    AlmacenesTable,
    StockAlmacenTable,
    TransferenciasTable,
    PresentacionesTable,
    ImpuestosTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  factory AppDatabase() => _instance;
  AppDatabase._internal() : super(_openConnection());
  static final AppDatabase _instance = AppDatabase._internal();
  CuentasCobrarDao get cuentasCobrarDao => CuentasCobrarDao(this);
  @override
  int get schemaVersion => 63;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await m.database.customStatement(_crearTablaBitacora);
      await m.database.customStatement(_crearColaSincronizacion);
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 62) {
        await customStatement(
          'ALTER TABLE ecfe_documentos_table ADD COLUMN rnc_receptor TEXT NULL;',
        );
      }
      if (from < 63) {
        await customStatement(
          'ALTER TABLE ecfe_documentos_table ADD COLUMN nota_fiscal_json TEXT NULL;',
        );
      }
      if (from < 60) {
        await m.createTable(impuestosTable);
      }
      if (from < 61) {
        await m.addColumn(productosTable, productosTable.impuestoId);
      }
      if (from < 59) {
        await customStatement(
          "ALTER TABLE categorias ADD COLUMN codigo TEXT NOT NULL DEFAULT '';",
        );
        await customStatement(
          'ALTER TABLE categorias ADD COLUMN padre_id INTEGER NULL;',
        );
        await customStatement(
          'ALTER TABLE categorias ADD COLUMN itbis_por_ciento REAL NULL;',
        );
        await customStatement(
          'ALTER TABLE categorias ADD COLUMN activo INTEGER NOT NULL DEFAULT 1;',
        );
        await customStatement(
          "ALTER TABLE marcas ADD COLUMN codigo TEXT NOT NULL DEFAULT '';",
        );
        await customStatement(
          'ALTER TABLE marcas ADD COLUMN fabricante TEXT NULL;',
        );
        await customStatement(
          'ALTER TABLE marcas ADD COLUMN activo INTEGER NOT NULL DEFAULT 1;',
        );
        await customStatement(
          "ALTER TABLE unidades_medida ADD COLUMN codigo TEXT NOT NULL DEFAULT '';",
        );
        await customStatement(
          'ALTER TABLE unidades_medida ADD COLUMN factor_a_base REAL NOT NULL DEFAULT 1.0;',
        );
        await customStatement(
          'ALTER TABLE unidades_medida ADD COLUMN es_base INTEGER NOT NULL DEFAULT 0;',
        );
        await customStatement(
          'ALTER TABLE unidades_medida ADD COLUMN activo INTEGER NOT NULL DEFAULT 1;',
        );
        await m.createTable(presentacionesTable);
      }
      if (from < 58) {
        await m.createTable(stockAlmacenTable);
        await m.createTable(transferenciasTable);
      }
      if (from < 57) {
        await m.createTable(almacenesTable);
      }
      if (from < 56) {
        await m.createTable(dispositivosLicenciaTable);
      }
      if (from < 55) {
        await m.createTable(licenciasTable);
        await m.createTable(pedidosLicenciaTable);
      }
      if (from < 54) {
        await customStatement(
          'ALTER TABLE ecfe_documentos_table ADD COLUMN encf_referencia TEXT NULL;',
        );
        await customStatement(
          'ALTER TABLE ecfe_documentos_table ADD COLUMN motivo_anulacion TEXT NULL;',
        );
      }

      if (from < 53) {
        await customStatement(
          'ALTER TABLE ecfe_documentos_table ADD COLUMN codigo_seguridad TEXT NULL;',
        );
      }

      if (from < 52) {
        await customStatement(
          'CREATE TABLE IF NOT EXISTS ecfe_spec_version_table ('
          'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
          'codigo TEXT NOT NULL, '
          'nombre TEXT NOT NULL, '
          'circular_dgii TEXT NULL, '
          "xsd_version TEXT NOT NULL DEFAULT '', "
          'notas TEXT NULL, '
          'activa_precert INTEGER NOT NULL DEFAULT 0, '
          'activa_cert INTEGER NOT NULL DEFAULT 0, '
          'activa_produccion INTEGER NOT NULL DEFAULT 0, '
          "checklist_json TEXT NOT NULL DEFAULT '[]', "
          'creado_en INTEGER NOT NULL, '
          'activado_en INTEGER NULL'
          ');',
        );
      }

      if (from < 50) {
        await customStatement(
          'CREATE TABLE IF NOT EXISTS ecfe_config_table ('
          'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
          'habilitado INTEGER NOT NULL DEFAULT 0, '
          "ambiente TEXT NOT NULL DEFAULT 'deshabilitado', "
          "rnc_emisor TEXT NOT NULL DEFAULT '', "
          "razon_social_emisor TEXT NOT NULL DEFAULT '', "
          "ruta_certificado TEXT NOT NULL DEFAULT '', "
          "alias_certificado TEXT NOT NULL DEFAULT '', "
          "clave_certificado TEXT NOT NULL DEFAULT '', "
          "xsd_version TEXT NOT NULL DEFAULT '', "
          'actualizado_en INTEGER NOT NULL'
          ');',
        );
        await customStatement(
          'CREATE TABLE IF NOT EXISTS ecfe_documentos_table ('
          'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
          'venta_id INTEGER NULL, '
          'tipo_ecf INTEGER NOT NULL, '
          'encf TEXT NULL, '
          "estado TEXT NOT NULL DEFAULT 'borrador', "
          'track_id TEXT NULL, '
          'codigo_respuesta TEXT NULL, '
          'mensaje_dgii TEXT NULL, '
          'ultimo_error TEXT NULL, '
          'xml_sin_firma TEXT NULL, '
          'xml_firmado TEXT NULL, '
          'creado_en INTEGER NOT NULL, '
          'actualizado_en INTEGER NULL'
          ');',
        );
        await customStatement(
          'CREATE TABLE IF NOT EXISTS ecfe_eventos_table ('
          'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
          'documento_id INTEGER NOT NULL, '
          'paso TEXT NOT NULL, '
          'detalle TEXT NULL, '
          'ok INTEGER NOT NULL DEFAULT 1, '
          'creado_en INTEGER NOT NULL'
          ');',
        );
        await customStatement(
          'CREATE TABLE IF NOT EXISTS ecfe_secuencias_table ('
          'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
          'tipo_ecf INTEGER NOT NULL, '
          'secuencia_actual INTEGER NOT NULL DEFAULT 0, '
          'secuencia_desde INTEGER NOT NULL DEFAULT 1, '
          'secuencia_hasta INTEGER NOT NULL DEFAULT 9999999999, '
          'fecha_vencimiento INTEGER NULL, '
          'activo INTEGER NOT NULL DEFAULT 1'
          ');',
        );
      }

      if (from < 48) {
        await m.createTable(ecfeSecuenciasTable);
      }
      if (from < 47) {
        await m.createTable(ecfeConfigTable);
        await m.createTable(ecfeDocumentosTable);
        await m.createTable(ecfeEventosTable);
      }
      if (from < 46) {
        await m.createTable(gastosTable);
      }
      if (from < 45) {
        await m.database.customStatement(_crearTablaBitacora);
        await m.database.customStatement(_crearColaSincronizacion);
      }
      if (from < 43) {
        await m.createTable(fiosTable);
      }
      if (from < 44) {
        for (final sql in [
          'ALTER TABLE usuarios_table ADD COLUMN requiere_setup_inicial INTEGER NOT NULL DEFAULT 1',
          'ALTER TABLE usuarios_table ADD COLUMN pregunta_recuperacion TEXT',
          'ALTER TABLE usuarios_table ADD COLUMN respuesta_hash TEXT',
        ]) {
          try {
            await m.database.customStatement(sql);
          } catch (_) {}
        }
      }
      if (from < 42) {
        await m.addColumn(ventasTable, ventasTable.comprobanteEntregaImpreso);
        await m.addColumn(ventasTable, ventasTable.fechaComprobanteEntrega);
      }

      if (from < 41) {
        await m.addColumn(clientesTable, clientesTable.whatsapp);
        await m.addColumn(ventasTable, ventasTable.clienteTelefono);
        await m.addColumn(ventasTable, ventasTable.clienteWhatsapp);
        await m.addColumn(ventasTable, ventasTable.clienteDireccion);
      }

      if (from < 40) {
        for (final sql in [
          'ALTER TABLE ventas_table ADD COLUMN numero_cuotas INTEGER NOT NULL DEFAULT 1',
          'ALTER TABLE ventas_table ADD COLUMN plazo_dias INTEGER NOT NULL DEFAULT 30',
          'ALTER TABLE ventas_table ADD COLUMN tasa_interes REAL NOT NULL DEFAULT 0.0',
          'ALTER TABLE ventas_table ADD COLUMN monto_interes REAL NOT NULL DEFAULT 0.0',
        ]) {
          try {
            await m.database.customStatement(sql);
          } catch (_) {
            // columna ya existe o nombre legacy
          }
        }
      }

      if (from < 33) {
        await m.createTable(notasCreditoTable);
      }
      if (from < 32) {
        await m.createTable(secuenciasNcfTable);
      }
      if (from < 31) {
        try {
          await customStatement(
            'ALTER TABLE productos_table ADD COLUMN stock_reservado REAL NOT NULL DEFAULT 0.0',
          );
        } catch (_) {}
      }
      if (from < 30) {
        await m.createTable(solicitudesCreditoTable);
        await m.createTable(referenciasCreditoTable);
      }

      if (from < 29) {
        await m.createTable(parametrosCreditoTable);
      }

      if (from < 28) {
        await m.createTable(cajaSesionesTable);
      }

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
      if (from < 15) {
        await m.alterTable(
          TableMigration(
            productosTable,
            newColumns: [productosTable.stockReservado],
          ),
        );
      }
      if (from < 17) {
        try {
          await m.database.customStatement(
            'ALTER TABLE ventas_table ADD COLUMN costo_envio REAL DEFAULT 0.0',
          );
        } catch (_) {}
        try {
          await m.database.customStatement(
            'ALTER TABLE ventas_table ADD COLUMN abono_inicial REAL DEFAULT 0.0',
          );
        } catch (_) {}
        try {
          await m.database.customStatement(
            'ALTER TABLE ventas_table ADD COLUMN vencimiento TEXT',
          );
        } catch (_) {}
      }
      if (from < 18) {
        try {
          await m.database.customStatement(
            'ALTER TABLE ventas_table ADD COLUMN estado TEXT DEFAULT "pendiente"',
          );
        } catch (_) {}
      }
      if (from < 19) {
        try {
          await m.database.customStatement(
            'ALTER TABLE ventas_table ADD COLUMN numero_cotizacion TEXT',
          );
        } catch (_) {}
      }
      if (from < 20) {
        try {
          await m.database.customStatement(
            'ALTER TABLE compras_table ADD COLUMN fecha_vencimiento TEXT',
          );
        } catch (_) {}
        try {
          await m.database.customStatement(
            'ALTER TABLE compras_table ADD COLUMN fecha_recepcion TEXT',
          );
        } catch (_) {}
        try {
          await m.database.customStatement(
            'ALTER TABLE compras_table ADD COLUMN ncf TEXT NOT NULL DEFAULT ""',
          );
        } catch (_) {}
        try {
          await m.database.customStatement(
            'ALTER TABLE compras_table ADD COLUMN forma_pago TEXT NOT NULL DEFAULT "contado"',
          );
        } catch (_) {}
        try {
          await m.database.customStatement(
            'ALTER TABLE compras_table ADD COLUMN dias_credito INTEGER NOT NULL DEFAULT 0',
          );
        } catch (_) {}
        try {
          await m.database.customStatement(
            'ALTER TABLE detalle_compra_table ADD COLUMN subtotal_linea REAL',
          );
        } catch (_) {}
        try {
          await m.database.customStatement(
            'ALTER TABLE detalle_compra_table ADD COLUMN base_imponible_linea REAL',
          );
        } catch (_) {}
        try {
          await m.database.customStatement(
            'ALTER TABLE detalle_compra_table ADD COLUMN itbis_linea REAL',
          );
        } catch (_) {}
        try {
          await m.database.customStatement(
            'ALTER TABLE detalle_compra_table ADD COLUMN total_linea REAL',
          );
        } catch (_) {}
      }
      if (from < 21) {
        await m.createTable(pagosProveedorTable);
      }
      if (from < 22) {
        await migrar002AgregarCamposProductos(m);
      }
      if (from < 23) {
        try {
          await m.database.customStatement(
            'ALTER TABLE proveedores_table ADD COLUMN whatsapp TEXT',
          );
        } catch (_) {}
        try {
          await m.database.customStatement(
            'ALTER TABLE proveedores_table ADD COLUMN limite_credito REAL NOT NULL DEFAULT 0.0',
          );
        } catch (_) {}
        try {
          await m.database.customStatement(
            'ALTER TABLE proveedores_table ADD COLUMN condiciones_nota TEXT',
          );
        } catch (_) {}
      }
      if (from < 24) {
        try {
          await m.database.customStatement(
            "ALTER TABLE compras_table ADD COLUMN tipo_comprobante TEXT NOT NULL DEFAULT '01'",
          );
        } catch (_) {}
        try {
          await m.database.customStatement(
            "ALTER TABLE compras_table ADD COLUMN condicion_pago TEXT NOT NULL DEFAULT 'contado'",
          );
        } catch (_) {}
        await m.database.customStatement('''
          UPDATE compras_table
          SET estado = CASE CAST(estado AS INTEGER)
            WHEN 0 THEN 'borrador'
            WHEN 1 THEN 'confirmada'
            WHEN 2 THEN 'registrada'
            WHEN 3 THEN 'recibida'
            WHEN 4 THEN 'pagada'
            WHEN 5 THEN 'vencida'
            WHEN 6 THEN 'anulada'
            ELSE COALESCE(estado, 'borrador')
          END
          WHERE typeof(estado) = 'integer'
             OR (typeof(estado) = 'text' AND estado GLOB '[0-9]*');
        ''');
      }
      if (from < 25) {
        try {
          await m.database.customStatement(
            'ALTER TABLE detalle_compra_table ADD COLUMN flete_unitario REAL DEFAULT 0.0',
          );
        } catch (_) {}
        try {
          await m.database.customStatement(
            'ALTER TABLE detalle_compra_table ADD COLUMN seguro_unitario REAL DEFAULT 0.0',
          );
        } catch (_) {}
        try {
          await m.database.customStatement(
            'ALTER TABLE detalle_compra_table ADD COLUMN aranceles_unitario REAL DEFAULT 0.0',
          );
        } catch (_) {}
        try {
          await m.database.customStatement(
            'ALTER TABLE detalle_compra_table ADD COLUMN gastos_unitario REAL DEFAULT 0.0',
          );
        } catch (_) {}
        try {
          await m.database.customStatement(
            'ALTER TABLE detalle_compra_table ADD COLUMN costo_adquisicion REAL',
          );
        } catch (_) {}
      }
      if (from < 26) {
        try {
          await m.database.customStatement(
            "ALTER TABLE compras_table ADD COLUMN estado TEXT NOT NULL DEFAULT 'borrador'",
          );
        } catch (_) {}
      }
      if (from < 27) {
        try {
          await m.database.customStatement(
            'ALTER TABLE compras_table ADD COLUMN fecha_pago TEXT',
          );
        } catch (_) {}
      }
      if (from < 34) {
        final cols = <String, String>{
          'razon_social': "TEXT NOT NULL DEFAULT ''",
          'direccion': "TEXT NOT NULL DEFAULT ''",
          'telefono': "TEXT NOT NULL DEFAULT ''",
          'correo': "TEXT NOT NULL DEFAULT ''",
          'logo_url': "TEXT NOT NULL DEFAULT ''",
          'zona_horaria': "TEXT NOT NULL DEFAULT 'America/Santo_Domingo'",
          'formato_impresion': "TEXT NOT NULL DEFAULT 'Ticket 80mm'",
        };
        for (final e in cols.entries) {
          try {
            await customStatement(
              'ALTER TABLE configuracion_table ADD COLUMN ${e.key} ${e.value}',
            );
          } catch (_) {}
        }
      }

      if (from < 35) {
        final cols = <String, String>{
          'doc_mostrar_logo': 'INTEGER NOT NULL DEFAULT 1',
          'doc_mostrar_rnc': 'INTEGER NOT NULL DEFAULT 1',
          'doc_mostrar_direccion': 'INTEGER NOT NULL DEFAULT 1',
          'doc_mostrar_telefono': 'INTEGER NOT NULL DEFAULT 1',
          'doc_mostrar_correo': 'INTEGER NOT NULL DEFAULT 1',
          'doc_mostrar_ncf': 'INTEGER NOT NULL DEFAULT 1',
          'doc_mostrar_cliente': 'INTEGER NOT NULL DEFAULT 1',
          'doc_mostrar_itbis_desglose': 'INTEGER NOT NULL DEFAULT 1',
          'doc_pie_pagina':
              "TEXT NOT NULL DEFAULT 'Gracias por su preferencia'",
        };
        for (final e in cols.entries) {
          try {
            await customStatement(
              'ALTER TABLE configuracion_table ADD COLUMN ${e.key} ${e.value}',
            );
          } catch (_) {}
        }
      }

      if (from < 36) {
        try {
          await customStatement(
            "ALTER TABLE configuracion_table ADD COLUMN prefijo_contado TEXT NOT NULL DEFAULT 'C'",
          );
        } catch (_) {}
        try {
          await customStatement(
            "ALTER TABLE configuracion_table ADD COLUMN prefijo_credito TEXT NOT NULL DEFAULT 'CR'",
          );
        } catch (_) {}
      }

      if (from < 37) {
        try {
          await customStatement(
            "ALTER TABLE configuracion_table ADD COLUMN caja_forma_pago_default TEXT NOT NULL DEFAULT 'efectivo'",
          );
        } catch (_) {}
        try {
          await customStatement(
            'ALTER TABLE configuracion_table ADD COLUMN caja_permitir_tarjeta INTEGER NOT NULL DEFAULT 1',
          );
        } catch (_) {}
        try {
          await customStatement(
            'ALTER TABLE configuracion_table ADD COLUMN caja_permitir_transferencia INTEGER NOT NULL DEFAULT 1',
          );
        } catch (_) {}
        try {
          await customStatement(
            'ALTER TABLE configuracion_table ADD COLUMN caja_permitir_cheque INTEGER NOT NULL DEFAULT 0',
          );
        } catch (_) {}
        try {
          await customStatement(
            'ALTER TABLE configuracion_table ADD COLUMN caja_exigir_sesion INTEGER NOT NULL DEFAULT 0',
          );
        } catch (_) {}
      }

      if (from < 38) {
        try {
          await customStatement(
            'ALTER TABLE configuracion_table ADD COLUMN modo_simplificado INTEGER NOT NULL DEFAULT 0',
          );
        } catch (_) {}
      }

      if (from < 39) {
        await m.createTable(cuotasCuentaTable);
      }
    },
  );
}

const _crearTablaBitacora = '''
  CREATE TABLE IF NOT EXISTS bitacora_operaciones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha TEXT NOT NULL,
    usuario_id INTEGER NOT NULL DEFAULT 0,
    accion TEXT NOT NULL,
    entidad TEXT NOT NULL,
    entidad_id INTEGER,
    resumen TEXT NOT NULL,
    datos TEXT
  )
  ''';

const _crearColaSincronizacion = '''
  CREATE TABLE IF NOT EXISTS cola_sincronizacion (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha_creacion TEXT NOT NULL,
    entidad TEXT NOT NULL,
    entidad_id INTEGER NOT NULL DEFAULT 0,
    accion TEXT NOT NULL,
    payload TEXT NOT NULL,
    estado TEXT NOT NULL DEFAULT 'pendiente',
    intentos INTEGER NOT NULL DEFAULT 0,
    ultimo_error TEXT
  )
  ''';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final carpetaBase = await getApplicationDocumentsDirectory();
    final archivoDb = File(p.join(carpetaBase.path, 'fiscogest_rd.sqlite'));
    return NativeDatabase.createInBackground(archivoDb);
  });
}

final appDatabaseProvider = Provider((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
