import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

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
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'fiscogestrd.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla Negocio (ya existente)
    await db.execute('''
      CREATE TABLE negocio (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        rnc TEXT,
        direccion TEXT,
        telefono TEXT,
        correo TEXT,
        actividad_economica TEXT
      );
    ''');

    // ✅ NUEVA TABLA: PRODUCTOS
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT NOT NULL UNIQUE,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        costo_compra REAL NOT NULL,
        gastos_transporte REAL NOT NULL DEFAULT 0,
        gastos_varios REAL NOT NULL DEFAULT 0,
        porcentaje_itbis REAL NOT NULL DEFAULT 18,
        exento_itbis INTEGER NOT NULL DEFAULT 0,
        margen_ganancia REAL NOT NULL,
        fecha_registro TEXT NOT NULL,
        activo INTEGER NOT NULL DEFAULT 1
      );
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      // Migraciones futuras aquí
    }
  }

  Future<void> close() async {
    if (_database != null) await _database!.close();
  }
}