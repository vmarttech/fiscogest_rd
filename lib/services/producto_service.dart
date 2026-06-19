import 'package:sqflite/sqflite.dart';
import 'package:fiscogestrd/models/producto.dart';
import 'package:fiscogestrd/services/db_service.dart';
import 'package:fiscogestrd/utils/logger.dart';

class ProductoService {
  final DbService _dbService = DbService();
  Future<Database> get database async => await _dbService.database;

  // =====================================================
  // OBTENER TODOS LOS PRODUCTOS
  // =====================================================
  Future<List<Producto>> obtenerTodos() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'productos',
        orderBy: 'nombre ASC',
      );
      return List.generate(maps.length, (i) => Producto.fromMap(maps[i]));
    } catch (e, traza) {
      AppLogger.error('Error al obtener productos', e, traza);
      return [];
    }
  }

  // =====================================================
  // OBTENER POR ID
  // =====================================================
  Future<Producto?> obtenerPorId(int id) async {
    try {
      final db = await database;
      final res = await db.query(
        'productos',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return res.isNotEmpty ? Producto.fromMap(res.first) : null;
    } catch (e, traza) {
      AppLogger.error('Error al obtener producto por ID', e, traza);
      return null;
    }
  }

  // =====================================================
  // OBTENER POR CÓDIGO
  // =====================================================
  Future<Producto?> obtenerPorCodigo(String codigo) async {
    try {
      final db = await database;
      final res = await db.query(
        'productos',
        where: 'codigo = ?',
        whereArgs: [codigo.trim()],
        limit: 1,
      );
      return res.isNotEmpty ? Producto.fromMap(res.first) : null;
    } catch (e, traza) {
      AppLogger.error('Error al obtener producto por código', e, traza);
      return null;
    }
  }

  // =====================================================
  // CREAR PRODUCTO
  // =====================================================
  Future<int> crear(Producto producto) async {
    try {
      final db = await database;
      final dato = producto.copyWith(fechaRegistro: DateTime.now());
      final idInsertado = await db.insert(
        'productos',
        dato.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      AppLogger.info('Producto creado correctamente', {
        'id': idInsertado,
        'codigo': producto.codigo,
      });
      return idInsertado;
    } catch (e, traza) {
      AppLogger.error('Error al crear producto', e, traza);
      return -1;
    }
  }

  // =====================================================
  // ACTUALIZAR PRODUCTO
  // =====================================================
  Future<int> actualizar(Producto producto) async {
    try {
      if (producto.id == null) return -1;
      final db = await database;
      final filasAfectadas = await db.update(
        'productos',
        producto.toMap(),
        where: 'id = ?',
        whereArgs: [producto.id],
      );
      AppLogger.info('Producto actualizado', {'id': producto.id});
      return filasAfectadas;
    } catch (e, traza) {
      AppLogger.error('Error al actualizar producto', e, traza);
      return -1;
    }
  }

  // =====================================================
  // ELIMINAR PRODUCTO
  // =====================================================
  Future<int> eliminar(int id) async {
    try {
      final db = await database;
      final filasAfectadas = await db.delete(
        'productos',
        where: 'id = ?',
        whereArgs: [id],
      );
      AppLogger.info('Producto eliminado', {'id': id});
      return filasAfectadas;
    } catch (e, traza) {
      AppLogger.error('Error al eliminar producto', e, traza);
      return -1;
    }
  }

  // =====================================================
  // MÉTODOS AUXILIARES DE CÁLCULO
  // =====================================================
  /// Obtiene un resumen con todos los valores calculados del producto
  Map<String, double> obtenerResumenCostos(Producto producto) {
    return {
      'costoSinImpuesto': producto.costoRealSinImpuesto,
      'totalImpuestos': producto.totalImpuestos,
      'costoConImpuesto': producto.costoRealConImpuesto,
      'precioSugerido': producto.precioVentaSugerido,
      'gananciaNeta': producto.gananciaNeta,
      'margenReal': producto.porcentajeGananciaReal,
    };
  }
}
