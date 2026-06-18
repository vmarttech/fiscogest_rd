import 'package:sqflite/sqflite.dart';
import '../models/existencia.dart';
import '../models/producto.dart';
import 'db_service.dart';
import '../utils/logger.dart';

class ExistenciaService {
  final DbService _dbService = DbService();
  Future<Database> get database async => await _dbService.database;

  // =====================================================
  // OBTENER TODOS ACTIVOS
  // =====================================================
  Future<List<Existencia>> obtenerTodosActivos() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT e.* FROM existencias e
        INNER JOIN productos p ON e.productoId = p.id
        WHERE p.activo = 1
        ORDER BY e.nombreProducto ASC
      ''');
      return List.generate(maps.length, (i) => Existencia.fromMap(maps[i]));
    } catch (e, traza) {
      AppLogger.error('Error al obtener existencias', e, traza);
      return [];
    }
  }

  // =====================================================
  // OBTENER POR PRODUCTO
  // =====================================================
  Future<Existencia?> obtenerPorProducto(int productoId) async {
    try {
      final db = await database;
      final res = await db.query(
        'existencias',
        where: 'productoId = ?',
        whereArgs: [productoId],
        limit: 1,
      );
      return res.isNotEmpty ? Existencia.fromMap(res.first) : null;
    } catch (e, traza) {
      AppLogger.error('Error al obtener existencia por producto', e, traza);
      return null;
    }
  }

  // =====================================================
  // CREAR
  // =====================================================
  Future<int> crear(Existencia existencia) async {
    try {
      final db = await database;
      final datoConFecha = existencia.ultimaActualizacion == null
          ? Existencia(
              id: existencia.id,
              productoId: existencia.productoId,
              codigoProducto: existencia.codigoProducto,
              nombreProducto: existencia.nombreProducto,
              cantidadDisponible: existencia.cantidadDisponible,
              cantidadReservada: existencia.cantidadReservada,
              cantidadMinima: existencia.cantidadMinima,
              cantidadMaxima: existencia.cantidadMaxima,
              ubicacion: existencia.ubicacion,
              ultimaActualizacion: DateTime.now(),
            )
          : existencia;

      return await db.insert(
        'existencias',
        datoConFecha.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, traza) {
      AppLogger.error('Error al crear existencia', e, traza);
      return -1;
    }
  }

  // =====================================================
  // ACTUALIZAR
  // =====================================================
  Future<int> actualizar(Existencia existencia) async {
    try {
      final db = await database;
      final datoActualizado = Existencia(
        id: existencia.id,
        productoId: existencia.productoId,
        codigoProducto: existencia.codigoProducto,
        nombreProducto: existencia.nombreProducto,
        cantidadDisponible: existencia.cantidadDisponible,
        cantidadReservada: existencia.cantidadReservada,
        cantidadMinima: existencia.cantidadMinima,
        cantidadMaxima: existencia.cantidadMaxima,
        ubicacion: existencia.ubicacion,
        ultimaActualizacion: DateTime.now(),
      );

      return await db.update(
        'existencias',
        datoActualizado.toMap(),
        where: 'id = ?',
        whereArgs: [existencia.id],
      );
    } catch (e, traza) {
      AppLogger.error('Error al actualizar existencia', e, traza);
      return -1;
    }
  }

  // =====================================================
  // ACTUALIZAR DATOS BÁSICOS DEL PRODUCTO EN INVENTARIO
  // =====================================================
  Future<void> actualizarDatosProductoRelacionado(Producto producto) async {
    try {
      if (producto.id == null) return;
      final db = await database;
      await db.update(
        'existencias',
        {
          'codigoProducto': producto.codigo,
          'nombreProducto': producto.nombre,
          'cantidadMinima': producto.stockMinimo.toDouble(),
          'ultimaActualizacion': DateTime.now().toIso8601String(),
        },
        where: 'productoId = ?',
        whereArgs: [producto.id],
      );
    } catch (e, traza) {
      AppLogger.error('Error al actualizar datos del producto en inventario', e, traza);
    }
  }

  // =====================================================
  // ELIMINAR
  // =====================================================
  Future<int> eliminar(int id) async {
    try {
      final db = await database;
      return await db.delete(
        'existencias',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, traza) {
      AppLogger.error('Error al eliminar existencia', e, traza);
      return -1;
    }
  }

  Future<int> eliminarPorProductoId(int productoId) async {
    try {
      final db = await database;
      return await db.delete(
        'existencias',
        where: 'productoId = ?',
        whereArgs: [productoId],
      );
    } catch (e, traza) {
      AppLogger.error('Error al eliminar existencia por ID de producto', e, traza);
      return -1;
    }
  }

  // =====================================================
  // INICIALIZAR EXISTENCIA AL CREAR PRODUCTO
  // =====================================================
  Future<void> inicializarExistenciaDeProducto(Producto producto) async {
    try {
      if (producto.id == null) return;
      final existe = await obtenerPorProducto(producto.id!);
      if (existe != null) return;

      final inventario = Existencia(
        productoId: producto.id!,
        codigoProducto: producto.codigo,
        nombreProducto: producto.nombre,
        cantidadDisponible: producto.stockActual.toDouble(),
        cantidadMinima: producto.stockMinimo.toDouble(),
        cantidadMaxima: 1000.0,
        ubicacion: 'Almacén Principal',
        ultimaActualizacion: DateTime.now(),
      );

      await crear(inventario);
      AppLogger.info('Existencia inicializada para producto', {'id': producto.id});
    } catch (e, traza) {
      AppLogger.error('Error al inicializar existencia', e, traza);
    }
  }

  // =====================================================
  // ACTUALIZAR STOCK Y REFLEJAR EN PRODUCTO
  // =====================================================
  Future<void> actualizarStockDesdeInventario(int productoId, double nuevoStock) async {
    try {
      final db = await database;

      await db.update(
        'existencias',
        {
          'cantidadDisponible': nuevoStock,
          'ultimaActualizacion': DateTime.now().toIso8601String(),
        },
        where: 'productoId = ?',
        whereArgs: [productoId],
      );

      await db.update(
        'productos',
        {'stockActual': nuevoStock},
        where: 'id = ?',
        whereArgs: [productoId],
      );

      AppLogger.info('Stock actualizado', {'producto': productoId, 'nuevoValor': nuevoStock});
    } catch (e, traza) {
      AppLogger.error('Error al actualizar stock', e, traza);
    }
  }
}