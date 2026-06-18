import 'package:sqflite/sqflite.dart';
import '../services/db_service.dart';
import '../models/producto.dart';
import '../services/existencia_service.dart';

class ProductoRepository {
  // ✅ INSTANCIA ÚNICA - MANTENIDA
  static final ProductoRepository _instance = ProductoRepository._internal();
  factory ProductoRepository() => _instance;
  ProductoRepository._internal();

  // ✅ CONEXIONES OFICIALES - SIN CAMBIOS
  final DbService _dbService = DbService();
  final ExistenciaService _existenciaService = ExistenciaService();

  Future<Database> get _db async => await _dbService.database;

  // =====================================================
  // ✅ OBTENER TODOS ACTIVOS (MODIFICADO: AHORA TRAE TODOS)
  // =====================================================
  Future<List<Producto>> obtenerTodosActivos() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      orderBy: 'nombre ASC',
    );
    return List.generate(maps.length, (i) => Producto.fromMap(maps[i]));
  }

  // =====================================================
  // ✅ OBTENER TODOS (SIN FILTRO) - AGREGADO PARA EVITAR ERROR
  // =====================================================
  Future<List<Producto>> obtenerTodos() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      orderBy: 'nombre ASC',
    );
    return List.generate(maps.length, (i) => Producto.fromMap(maps[i]));
  }

  // =====================================================
  // ✅ OBTENER POR ID (MODIFICADO: AHORA BUSCA EN TODOS)
  // =====================================================
  Future<Producto?> obtenerPorId(int id) async {
    final db = await _db;
    final res = await db.query(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return Producto.fromMap(res.first);
  }

  // =====================================================
  // ✅ CREAR NUEVO PRODUCTO
  // =====================================================
  Future<int> crear(Producto producto) async {
    final db = await _db;

    // ✅ INSERCIÓN ALINEADA CON MODELO Y BD
    final id = await db.insert(
      'productos',
      producto.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    // ✅ INTEGRACIÓN INVENTARIO: CREACIÓN AUTOMÁTICA
    await _existenciaService.inicializarExistenciaDeProducto(
      producto.copyWith(id: id),
    );

    return id;
  }

  // =====================================================
  // ✅ ACTUALIZAR PRODUCTO EXISTENTE - ✅ RESTAURADO A VERSIÓN ORIGINAL
  // =====================================================
  Future<int> actualizar(Producto producto) async {
    final db = await _db;

    // ✅ RESTAURADO: FILTRO ORIGINAL `activo = 1`
    final filasAfectadas = await db.update(
      'productos',
      producto.toMap(),
      where: 'id = ? AND activo = ?',
      whereArgs: [producto.id, 1],
    );

    // ✅ PUNTO 5: SINCRONIZACIÓN CRÍTICA
    if (filasAfectadas > 0 && producto.id != null) {
      await _existenciaService.actualizarDatosProductoRelacionado(producto);
    }

    return filasAfectadas;
  }

  // =====================================================
  // ✅ GUARDAR: LÓGICA ÚNICA (CREA O ACTUALIZA)
  // =====================================================
  Future<int> guardar(Producto producto) async {
    return producto.id == null 
      ? await crear(producto)   
      : await actualizar(producto); 
  }

  // =====================================================
  // ✅ BUSCAR POR TEXTO (MODIFICADO: BUSCA EN TODOS)
  // =====================================================
  Future<List<Producto>> buscar(String texto) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: '(codigo LIKE ? OR nombre LIKE ? OR descripcion LIKE ?)',
      whereArgs: ['%$texto%', '%$texto%', '%$texto%'],
      orderBy: 'nombre ASC',
    );
    return List.generate(maps.length, (i) => Producto.fromMap(maps[i]));
  }

  // =====================================================
  // ✅ NUEVO: BUSCAR POR RÉGIMEN FISCAL (MODIFICADO: TRAE TODOS)
  // =====================================================
  Future<List<Producto>> buscarPorRegimen(String nombreRegimen) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: 'regimenImpuesto = ?',
      whereArgs: [nombreRegimen],
      orderBy: 'nombre ASC',
    );
    return List.generate(maps.length, (i) => Producto.fromMap(maps[i]));
  }

  // =====================================================
  // ✅ ELIMINACIÓN LÓGICA (SE MANTIENE IGUAL, FUNCIONA BIEN)
  // =====================================================
  Future<int> eliminarLogico(int id) async {
    final db = await _db;
    return await db.update(
      'productos',
      {'activo': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =====================================================
  // ✅ ELIMINACIÓN FÍSICA
  // =====================================================
  Future<int> eliminarFisico(int id) async {
    final db = await _db;
    await _existenciaService.eliminarPorProductoId(id);
    return await db.delete(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =====================================================
  // ✅ ACTUALIZACIÓN DE STOCK
  // =====================================================
  Future<void> actualizarNivelStock(int productoId, double nuevoValor) async {
    await _existenciaService.actualizarStockDesdeInventario(productoId, nuevoValor);
  }
}