import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/cliente.dart';

class ClienteService {
  // ✅ PATRÓN SINGLETON: Instancia única en todo el sistema
  static final ClienteService _instance = ClienteService._internal();
  factory ClienteService() => _instance;
  ClienteService._internal();

  static Database? _database;

  // ✅ GETTER OPTIMIZADO: Conexión perezosa y segura
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 🚀 INICIALIZACIÓN: Ruta y apertura
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'fiscogestrd.db');
    
    return await openDatabase(
      path,
      version: 4, // ⚠️ Aumenta este número si cambias estructura
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: onDatabaseDowngradeDelete, // 🔧 Seguridad si baja versión
    );
  }

  // 📦 CREACIÓN INICIAL: Todas las tablas desde cero
  Future<void> _onCreate(Database db, int version) async {
    // Tabla Productos
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT NOT NULL UNIQUE,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        costoCompra REAL NOT NULL DEFAULT 0,
        gastosTransporte REAL NOT NULL DEFAULT 0,
        gastosVarios REAL NOT NULL DEFAULT 0,
        margenGanancia REAL NOT NULL DEFAULT 0,
        categoriaId TEXT NOT NULL DEFAULT 'GENERAL',
        nombreCategoria TEXT NOT NULL DEFAULT 'Bienes y Servicios Generales',
        exentoITBIS INTEGER NOT NULL DEFAULT 0,
        porcentajeITBIS REAL NOT NULL DEFAULT 18.0,
        impuestoAdicional REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // Tabla Existencias / Inventario
    await db.execute('''
      CREATE TABLE existencias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productoId INTEGER NOT NULL UNIQUE,
        codigoProducto TEXT NOT NULL,
        nombreProducto TEXT NOT NULL,
        cantidadDisponible REAL NOT NULL DEFAULT 0,
        cantidadReservada REAL NOT NULL DEFAULT 0,
        cantidadMinima REAL NOT NULL DEFAULT 5,
        cantidadMaxima REAL NOT NULL DEFAULT 1000,
        ubicacion TEXT NOT NULL DEFAULT 'Almacén Principal',
        ultimaActualizacion TEXT NOT NULL,
        FOREIGN KEY (productoId) REFERENCES productos (id) ON DELETE CASCADE
      )
    ''');

    // Tabla Clientes (La que usamos ahora)
    await db.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        identificacion TEXT NOT NULL UNIQUE,
        tipoIdentificacion TEXT NOT NULL,
        direccion TEXT,
        telefono TEXT,
        correo TEXT,
        exentoITBIS INTEGER NOT NULL DEFAULT 0,
        regimenFiscal TEXT NOT NULL DEFAULT 'Normal',
        fechaRegistro TEXT NOT NULL
      )
    ''');
  }

  // 🔄 ACTUALIZACIÓN DE ESTRUCTURA (Versiones)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Versión 2: Agregamos campos fiscales a productos
    if (oldVersion < 2) {
      await _agregarColumnaSiNoExiste(db, 'productos', 'categoriaId', 'TEXT DEFAULT "GENERAL"');
      await _agregarColumnaSiNoExiste(db, 'productos', 'nombreCategoria', 'TEXT DEFAULT "Bienes y Servicios Generales"');
      await _agregarColumnaSiNoExiste(db, 'productos', 'exentoITBIS', 'INTEGER DEFAULT 0');
      await _agregarColumnaSiNoExiste(db, 'productos', 'porcentajeITBIS', 'REAL DEFAULT 18.0');
      await _agregarColumnaSiNoExiste(db, 'productos', 'impuestoAdicional', 'REAL DEFAULT 0.0');
    }

    // Versión 3: Creamos tabla de existencias si no existe
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS existencias (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          productoId INTEGER NOT NULL UNIQUE,
          codigoProducto TEXT NOT NULL,
          nombreProducto TEXT NOT NULL,
          cantidadDisponible REAL NOT NULL DEFAULT 0,
          cantidadReservada REAL NOT NULL DEFAULT 0,
          cantidadMinima REAL NOT NULL DEFAULT 5,
          cantidadMaxima REAL NOT NULL DEFAULT 1000,
          ubicacion TEXT NOT NULL DEFAULT 'Almacén Principal',
          ultimaActualizacion TEXT NOT NULL,
          FOREIGN KEY (productoId) REFERENCES productos (id) ON DELETE CASCADE
        )
      ''');
    }

    // Versión 4: Creamos tabla de clientes si no existe
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS clientes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          identificacion TEXT NOT NULL UNIQUE,
          tipoIdentificacion TEXT NOT NULL,
          direccion TEXT,
          telefono TEXT,
          correo TEXT,
          exentoITBIS INTEGER NOT NULL DEFAULT 0,
          regimenFiscal TEXT NOT NULL DEFAULT 'Normal',
          fechaRegistro TEXT NOT NULL
        )
      ''');
    }
  }

  // 🛠️ FUNCIÓN AUXILIAR: Evita errores al agregar columnas nuevas
  Future<void> _agregarColumnaSiNoExiste(
      Database db, String tabla, String columna, String definicion) async {
    final resultado = await db.rawQuery('PRAGMA table_info($tabla)');
    final existe = resultado.any((fila) => fila['name'] == columna);
    if (!existe) {
      await db.execute('ALTER TABLE $tabla ADD COLUMN $columna $definicion');
    }
  }

  // ==================================================
  // 📌 MÉTODOS PRINCIPALES PARA CLIENTES
  // ==================================================

  // ➕ CREAR NUEVO CLIENTE
  Future<int> crear(Cliente cliente) async {
    try {
      final db = await database;
      return await db.insert(
        'clientes',
        cliente.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      rethrow; // Propaga error para manejarlo en el Provider
    }
  }

  // ✏️ ACTUALIZAR CLIENTE EXISTENTE
  Future<int> actualizar(Cliente cliente) async {
    try {
      final db = await database;
      return await db.update(
        'clientes',
        cliente.toMap(),
        where: 'id = ?',
        whereArgs: [cliente.id],
      );
    } catch (e) {
      rethrow;
    }
  }

  // 📄 OBTENER TODOS (Ordenados alfabéticamente)
  Future<List<Cliente>> obtenerTodos() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'clientes',
        orderBy: 'nombre ASC',
      );
      return List.generate(maps.length, (i) => Cliente.fromMap(maps[i]));
    } catch (e) {
      rethrow;
    }
  }

  // 🔍 BUSCAR POR ID
  Future<Cliente?> obtenerPorId(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'clientes',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return maps.isNotEmpty ? Cliente.fromMap(maps.first) : null;
    } catch (e) {
      return null;
    }
  }

  // 🗑️ ELIMINAR CLIENTE
  Future<int> eliminar(int id) async {
    try {
      final db = await database;
      return await db.delete(
        'clientes',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      rethrow;
    }
  }

  // 💾 GUARDAR INTELIGENTE: Si tiene ID -> Actualiza, si no -> Crea
  Future<int> guardar(Cliente cliente) async {
    return cliente.id == null ? crear(cliente) : actualizar(cliente);
  }

  // ==================================================
  // ⚙️ MÉTODOS ADICIONALES (Útiles para el futuro)
  // ==================================================

  // 🔎 BUSCAR POR RNC / CÉDULA
  Future<Cliente?> obtenerPorIdentificacion(String numero) async {
    final db = await database;
    final res = await db.query(
      'clientes',
      where: 'identificacion = ?',
      whereArgs: [numero.trim()],
      limit: 1,
    );
    return res.isNotEmpty ? Cliente.fromMap(res.first) : null;
  }

  // 🧹 CERRAR CONEXIÓN (Para cuando salgas de la app)
  Future<void> cerrar() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}