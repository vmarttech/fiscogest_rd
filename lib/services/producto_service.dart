import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/producto.dart';
import 'existencia_service.dart';

class ProductoService {
  static final ProductoService _instance = ProductoService._internal();
  factory ProductoService() => _instance;
  ProductoService._internal();

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
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT NOT NULL UNIQUE,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        
        precioCosto REAL NOT NULL DEFAULT 0,
        gastosTransporte REAL NOT NULL DEFAULT 0,
        gastosVarios REAL NOT NULL DEFAULT 0,
        margenGanancia REAL NOT NULL DEFAULT 0,
        precioVenta REAL NOT NULL DEFAULT 0,
        
        stockMinimo INTEGER NOT NULL DEFAULT 5,
        stockActual INTEGER NOT NULL DEFAULT 0,

        categoria TEXT NOT NULL DEFAULT 'GENERAL',
        exentoITBIS INTEGER NOT NULL DEFAULT 0,
        itbis REAL NOT NULL DEFAULT 18.0,
        impuestoAdicional REAL NOT NULL DEFAULT 0.0,
        
        fechaRegistro TEXT NOT NULL
      )
    ''');

    if (version >= 3) {
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE productos ADD COLUMN categoria TEXT DEFAULT "GENERAL"');
      await db.execute('ALTER TABLE productos ADD COLUMN exentoITBIS INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE productos ADD COLUMN itbis REAL DEFAULT 18.0');
      await db.execute('ALTER TABLE productos ADD COLUMN impuestoAdicional REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE productos ADD COLUMN precioVenta REAL DEFAULT 0');
      await db.execute('ALTER TABLE productos ADD COLUMN stockMinimo INTEGER DEFAULT 5');
      await db.execute('ALTER TABLE productos ADD COLUMN stockActual INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE productos ADD COLUMN fechaRegistro TEXT DEFAULT ""');
    }

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
  }

  Future<List<Producto>> obtenerTodosActivos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      orderBy: 'nombre ASC'
    );
    return List.generate(maps.length, (i) => Producto.fromMap(maps[i]));
  }

  Future<int> crear(Producto producto) async {
    final db = await database;
    
    // ✅ CORREGIDO: fechaRegistro es obligatorio, no puede ser null
    // Eliminada comparación innecesaria y código muerto
    final id = await db.insert(
      'productos',
      producto.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final servicioExistencia = ExistenciaService();
    await servicioExistencia.inicializarExistenciaDeProducto(producto.copyWith(id: id));

    return id;
  }

  Future<int> actualizar(Producto producto) async {
    final db = await database;
    return await db.update(
      'productos',
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  Future<List<Producto>> obtenerTodos() async => await obtenerTodosActivos();

  Future<int> guardarProducto(Producto producto) async {
    return producto.id == null ? await crear(producto) : await actualizar(producto);
  }

  Future<List<Producto>> buscar(String texto) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: 'codigo LIKE ? OR nombre LIKE ?',
      whereArgs: ['%$texto%', '%$texto%'],
      orderBy: 'nombre ASC',
    );
    return List.generate(maps.length, (i) => Producto.fromMap(maps[i]));
  }

  Future<int> eliminar(int id) async {
    final db = await database;
    return await db.delete(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}