import 'package:sqflite/sqflite.dart';
import '../models/existencia.dart';
import '../models/producto.dart';
import 'db_service.dart';

class ExistenciaService {
  final DbService _dbService = DbService();
  Future<Database> get database async => await _dbService.database;

  // =====================================================
  // OBTENER TODOS ACTIVOS
  // =====================================================
  Future<List<Existencia>> obtenerTodosActivos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT e.* FROM existencias e
      INNER JOIN productos p ON e.productoId = p.id
      WHERE p.activo = 1
      ORDER BY e.nombreProducto ASC
    ''');
    return List.generate(maps.length, (i) => Existencia.fromMap(maps[i]));
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
    return res.isNotEmpty ? Existencia.fromMap(res.first) : null;
  }

  // =====================================================
  // CREAR
  // =====================================================
  Future<int> crear(Existencia existencia) async {
    final db = await database;
    // ✅ ASEGURAMOS FECHA AL CREAR SI NO VIENE
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
  }

  // =====================================================
  // ACTUALIZAR
  // =====================================================
  Future<int> actualizar(Existencia existencia) async {
    final db = await database;
    // ✅ REGLA HOMOLOGADA: Cualquier edición = Actualizar fecha
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
  }

  // =====================================================
  // ACTUALIZAR DATOS PRODUCTO (SIN TOCAR STOCK)
  // =====================================================
  Future<void> actualizarDatosProductoRelacionado(Producto producto) async {
    if (producto.id == null) return;
    final db = await database;
    await db.update(
      'existencias',
      {
        'codigoProducto': producto.codigo,
        'nombreProducto': producto.nombre,
        'cantidadMinima': producto.stockMinimo.toDouble(), // ✅ ASEGURAMOS DOBLE
        'ultimaActualizacion': DateTime.now().toIso8601String(),
      },
      where: 'productoId = ?',
      whereArgs: [producto.id],
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

  Future<int> eliminarPorProductoId(int productoId) async {
    final db = await database;
    return await db.delete(
      'existencias',
      where: 'productoId = ?',
      whereArgs: [productoId],
    );
  }

  // =====================================================
  // INICIALIZAR EXISTENCIA AL CREAR PRODUCTO
  // =====================================================
  Future<void> inicializarExistenciaDeProducto(Producto producto) async {
    if (producto.id == null) return;
    final existe = await obtenerPorProducto(producto.id!);
    if (existe != null) return; // ✅ EVITA DUPLICADOS

    final inventario = Existencia(
      productoId: producto.id!,
      codigoProducto: producto.codigo,
      nombreProducto: producto.nombre,
      cantidadDisponible: producto.stockActual.toDouble(), // ✅ ADMITE DECIMALES
      cantidadMinima: producto.stockMinimo.toDouble(),     // ✅ ADMITE DECIMALES
      cantidadMaxima: 1000.0,
      ubicacion: 'Almacén Principal',
      ultimaActualizacion: DateTime.now(),
    );

    await crear(inventario);
  }

  // =====================================================
  // ✅ MÉTODO CRÍTICO: ACTUALIZAR STOCK
  // ✅ CORREGIDO: YA NO CONVIERTE A INT, MANTIENE DECIMALES
  // =====================================================
  Future<void> actualizarStockDesdeInventario(int productoId, double nuevoStock) async {
    final db = await database;

    // 1. Actualizamos en la tabla de inventario (existencias)
    await db.update(
      'existencias',
      {
        'cantidadDisponible': nuevoStock,
        'ultimaActualizacion': DateTime.now().toIso8601String(),
      },
      where: 'productoId = ?',
      whereArgs: [productoId],
    );

    // 2. Actualizamos reflejo en la tabla maestro (productos)
    // ✅ HOMOLOGACIÓN: GUARDAMOS COMO DOUBLE PARA COINCIDIR CON BD V6
    await db.update(
      'productos',
      {'stockActual': nuevoStock}, // <-- CORRECCIÓN PRINCIPAL: ANTES TENÍA .toInt()
      where: 'id = ?',
      whereArgs: [productoId],
    );
  }
}