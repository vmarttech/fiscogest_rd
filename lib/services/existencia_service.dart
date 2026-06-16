import 'package:sqflite/sqflite.dart';
import '../models/existencia.dart';
import '../models/producto.dart';
import 'producto_service.dart';

class ExistenciaService {
  final ProductoService _dbService = ProductoService();

  Future<Database> get database async => await _dbService.database;

  // =====================================================
  // OBTENER TODO EL INVENTARIO
  // =====================================================

  Future<List<Existencia>> obtenerTodosActivos() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'existencias',
      orderBy: 'nombreProducto ASC',
    );

    return List.generate(
      maps.length,
      (i) => Existencia.fromMap(maps[i]),
    );
  }

  // =====================================================
  // OBTENER POR PRODUCTO
  // =====================================================

  Future<Existencia?> obtenerPorProducto(int productoId) async {
    final db = await database;

    final res = await db.query(
      'existencias',
      where: 'productoId = ?',
      whereArgs: [productoId],
      limit: 1,
    );

    if (res.isEmpty) return null;

    return Existencia.fromMap(res.first);
  }

  // =====================================================
  // CREAR
  // =====================================================

  Future<int> crear(Existencia existencia) async {
    final db = await database;

    return await db.insert(
      'existencias',
      existencia.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // =====================================================
  // ACTUALIZAR
  // =====================================================

  Future<int> actualizar(Existencia existencia) async {
    final db = await database;

    return await db.update(
      'existencias',
      existencia.toMap(),
      where: 'id = ?',
      whereArgs: [existencia.id],
    );
  }

  // =====================================================
  // ELIMINAR
  // =====================================================

  Future<int> eliminar(int id) async {
    final db = await database;

    return await db.delete(
      'existencias',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =====================================================
  // INICIALIZAR EXISTENCIA DE UN PRODUCTO NUEVO
  // =====================================================

  Future<void> inicializarExistenciaDeProducto(
    Producto producto,
  ) async {
    if (producto.id == null) return;

    final existe = await obtenerPorProducto(
      producto.id!,
    );

    if (existe != null) return;

    final inventario = Existencia(
      productoId: producto.id!,
      codigoProducto: producto.codigo,
      nombreProducto: producto.nombre,
      cantidadDisponible:
          producto.stockActual.toDouble(),
      cantidadMinima:
          producto.stockMinimo.toDouble(),
    );

    await crear(inventario);
  }
}