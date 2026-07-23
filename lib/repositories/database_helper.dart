import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  // 1. Constructor principal
  DatabaseHelper._init();

  // 2. Campos estáticos
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fiscogestrd.db');
    return _database!;
  }

  Future<Database> _initDB(String nombre) async {
    final Directory documentosDir = await getApplicationDocumentsDirectory();
    final String rutaDB = join(documentosDir.path, nombre);

    return await openDatabase(
      rutaDB,
      version: 1,
      onCreate: _crearDB,
      onUpgrade: _actualizarDB,
    );
  }

  // ignore: avoid-unused-parameters
  Future<void> _crearDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT NOT NULL,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        precioCompra REAL NOT NULL,
        gastosTransporte REAL NOT NULL,
        gastosVarios REAL NOT NULL,
        precioVenta REAL NOT NULL,
        margenGanancia REAL NOT NULL,
        valorITBIS REAL NOT NULL,
        porcentajeImpuesto REAL NOT NULL,
        aplicaImpuesto INTEGER NOT NULL,
        categoria TEXT NOT NULL,
        regimenImpuesto TEXT NOT NULL,
        esImpuestoSelectivo INTEGER NOT NULL,
        unidadMedida TEXT NOT NULL,
        permiteDecimales INTEGER NOT NULL,
        stockActual REAL NOT NULL,
        stockMinimo REAL NOT NULL,
        fechaRegistro TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE compras (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numeroComprobante TEXT NOT NULL,
        fecha TEXT NOT NULL,
        proveedor TEXT NOT NULL,
        rncProveedor TEXT,
        subTotal REAL NOT NULL,
        itbisAcreditable REAL NOT NULL,
        impuestoSelectivo REAL NOT NULL,
        total REAL NOT NULL,
        observacion TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numeroComprobante TEXT NOT NULL,
        fecha TEXT NOT NULL,
        cliente TEXT NOT NULL,
        rncCliente TEXT,
        subTotal REAL NOT NULL,
        itbisGenerado REAL NOT NULL,
        impuestoSelectivo REAL NOT NULL,
        total REAL NOT NULL,
        observacion TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE detalles_operacion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipoOperacion TEXT NOT NULL,
        operacionId INTEGER NOT NULL,
        productoId INTEGER NOT NULL,
        codigoProducto TEXT NOT NULL,
        nombreProducto TEXT NOT NULL,
        cantidad REAL NOT NULL,
        precioUnitario REAL NOT NULL,
        aplicaImpuesto INTEGER NOT NULL,
        porcentajeImpuesto REAL NOT NULL,
        esImpuestoSelectivo INTEGER NOT NULL,
        subTotal REAL NOT NULL,
        valorImpuesto REAL NOT NULL,
        totalLinea REAL NOT NULL,
        FOREIGN KEY (productoId) REFERENCES productos (id) ON DELETE RESTRICT
      )
    ''');
  }

  // ✅ Bloque vacío corregido según la guía
  // ignore: avoid-unused-parameters
  Future<void> _actualizarDB(Database db, int oldVersion, int newVersion) async {
    // No hay cambios de estructura en esta versión
    await Future<void>.value();
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}