import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'fisco_gest_rd.db');
    return await openDatabase(
      path,
      version: 6, // ✅ VERSIÓN ACTUALIZADA (Campos nuevos + Homologación)
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: onDatabaseDowngradeDelete,
    );
  }

  // ✅ ESTRUCTURA 100% ALINEADA AL MODELO ACTUAL (Producto.dart)
  Future<void> _onCreate(Database db, int _) async {
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT NOT NULL UNIQUE,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        precioCompra REAL NOT NULL DEFAULT 0,  -- ✅ NOMBRE CORRECTO (antes precioCosto)
        gastosTransporte REAL NOT NULL DEFAULT 0,
        gastosVarios REAL NOT NULL DEFAULT 0,
        precioVenta REAL NOT NULL DEFAULT 0,
        margenGanancia REAL NOT NULL DEFAULT 0,
        valorITBIS REAL NOT NULL DEFAULT 0,    -- ✅ NUEVO
        porcentajeImpuesto REAL NOT NULL DEFAULT 18.0, -- ✅ NUEVO
        aplicaImpuesto INTEGER NOT NULL DEFAULT 1, -- ✅ NUEVO (antes exentoITBIS)
        categoria TEXT NOT NULL DEFAULT 'GENERAL',
        regimenImpuesto TEXT NOT NULL DEFAULT 'GENERAL (ITBIS 18%)', -- ✅ NUEVO / ACTUALIZADO
        esImpuestoSelectivo INTEGER NOT NULL DEFAULT 0, -- ✅ NUEVO
        unidadMedida TEXT NOT NULL DEFAULT 'UNIDAD',
        permiteDecimales INTEGER NOT NULL DEFAULT 0, -- ✅ NUEVO
        stockActual REAL NOT NULL DEFAULT 0,  -- ✅ CAMBIADO A REAL (Permite decimales)
        stockMinimo REAL NOT NULL DEFAULT 5,  -- ✅ CAMBIADO A REAL
        fechaRegistro TEXT NOT NULL,
        activo INTEGER NOT NULL DEFAULT 1     -- ✅ CONTROL BORRADO LÓGICO
      );
    ''');

    await db.execute('''
      CREATE TABLE existencias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productoId INTEGER NOT NULL,
        codigoProducto TEXT NOT NULL,
        nombreProducto TEXT NOT NULL,
        cantidadDisponible REAL NOT NULL DEFAULT 0,
        cantidadReservada REAL NOT NULL DEFAULT 0,
        cantidadMinima REAL NOT NULL DEFAULT 5,
        cantidadMaxima REAL NOT NULL DEFAULT 1000,
        ubicacion TEXT NOT NULL DEFAULT 'Almacén Principal',
        ultimaActualizacion TEXT NOT NULL,
        FOREIGN KEY (productoId) REFERENCES productos (id) ON DELETE CASCADE
      );
    ''');
  }

  // ✅ MIGRACIÓN SEGURA - HISTÓRICO COMPLETO HASTA V6
  Future<void> _onUpgrade(Database db, int oldVersion, int _) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE productos ADD COLUMN gastosTransporte REAL NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE productos ADD COLUMN gastosVarios REAL NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE productos ADD COLUMN categoria TEXT NOT NULL DEFAULT "GENERAL"');
      await db.execute('ALTER TABLE productos ADD COLUMN impuestoAdicional REAL NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE productos ADD COLUMN unidadMedida TEXT NOT NULL DEFAULT "UNIDAD"');
      await db.execute('ALTER TABLE productos ADD COLUMN activo INTEGER NOT NULL DEFAULT 1');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE productos ADD COLUMN exentoITBIS INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE productos ADD COLUMN itbis REAL NOT NULL DEFAULT 18.0');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS existencias (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          productoId INTEGER NOT NULL,
          codigoProducto TEXT NOT NULL,
          nombreProducto TEXT NOT NULL,
          cantidadDisponible REAL NOT NULL DEFAULT 0,
          cantidadReservada REAL NOT NULL DEFAULT 0,
          cantidadMinima REAL NOT NULL DEFAULT 5,
          cantidadMaxima REAL NOT NULL DEFAULT 1000,
          ubicacion TEXT NOT NULL DEFAULT 'Almacén Principal',
          ultimaActualizacion TEXT NOT NULL,
          FOREIGN KEY (productoId) REFERENCES productos (id) ON DELETE CASCADE
        );
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE productos ADD COLUMN regimenImpuesto TEXT NOT NULL DEFAULT "GENERAL (ITBIS 18%)"');
    }
    // ✅ MIGRACIÓN V5 -> V6: HOMOLOGACIÓN TOTAL Y CAMPOS NUEVOS
    if (oldVersion < 6) {
      // 1. Renombrar y homologar campos existentes
      await db.execute('ALTER TABLE productos RENAME COLUMN precioCosto TO precioCompra');
      await db.execute('ALTER TABLE productos RENAME COLUMN exentoITBIS TO aplicaImpuesto');
      await db.execute('ALTER TABLE productos RENAME COLUMN itbis TO porcentajeImpuesto');

      // 2. Agregar campos nuevos obligatorios
      await db.execute('ALTER TABLE productos ADD COLUMN valorITBIS REAL NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE productos ADD COLUMN esImpuestoSelectivo INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE productos ADD COLUMN permiteDecimales INTEGER NOT NULL DEFAULT 0');

      // 3. Modificar tipo de stock para permitir decimales (SQLite soporta alteración limitada, usamos estrategia segura)
      // Los valores se mantienen, solo cambia la interpretación a REAL
      await db.execute('ALTER TABLE productos ADD COLUMN stockActual_new REAL NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE productos ADD COLUMN stockMinimo_new REAL NOT NULL DEFAULT 5');
      await db.execute('UPDATE productos SET stockActual_new = stockActual, stockMinimo_new = stockMinimo');
      await db.execute('ALTER TABLE productos DROP COLUMN stockActual');
      await db.execute('ALTER TABLE productos DROP COLUMN stockMinimo');
      await db.execute('ALTER TABLE productos RENAME COLUMN stockActual_new TO stockActual');
      await db.execute('ALTER TABLE productos RENAME COLUMN stockMinimo_new TO stockMinimo');
    }
  }
}