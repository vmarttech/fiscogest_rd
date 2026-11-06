import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/promocion.dart';

class PromocionDatasource {
  PromocionDatasource(this._db);

  final AppDatabase _db;

  static const String _columnas = '''
    id,
    nombre,
    descripcion,
    tipo,
    valor,
    fecha_inicio AS fechaInicio,
    fecha_fin AS fechaFin,
    activa,
    minimo_cantidad AS minimoCantidad,
    minimo_monto AS minimoMonto
  ''';

  Future<List<Map<String, dynamic>>> listarTodos() async {
    final filas = await _db
        .customSelect(
          'SELECT $_columnas FROM promociones_comerciales ORDER BY id DESC',
        )
        .get();
    return filas.map((fila) => fila.data).toList();
  }

  Future<List<Map<String, dynamic>>> listarActivas() async {
    final filas = await _db
        .customSelect(
          'SELECT $_columnas FROM promociones_comerciales '
          'WHERE activa = 1 ORDER BY id DESC',
        )
        .get();
    return filas.map((fila) => fila.data).toList();
  }

  Future<Map<String, dynamic>?> buscarPorId(int id) async {
    final filas = await _db
        .customSelect(
          'SELECT $_columnas FROM promociones_comerciales '
          'WHERE id = ? LIMIT 1',
          variables: [Variable.withInt(id)],
        )
        .get();
    return filas.isEmpty ? null : filas.first.data;
  }

  Future<List<int>> listarProductoIds(int promocionId) async {
    final filas = await _db
        .customSelect(
          'SELECT producto_id FROM promocion_productos '
          'WHERE promocion_id = ? ORDER BY producto_id',
          variables: [Variable.withInt(promocionId)],
        )
        .get();

    return filas
        .map((fila) => (fila.data['producto_id'] as num).toInt())
        .toList();
  }

  Future<List<int>> listarCategoriaIds(int promocionId) async {
    final filas = await _db
        .customSelect(
          'SELECT categoria_id FROM promocion_categorias '
          'WHERE promocion_id = ? ORDER BY categoria_id',
          variables: [Variable.withInt(promocionId)],
        )
        .get();

    return filas
        .map((fila) => (fila.data['categoria_id'] as num).toInt())
        .toList();
  }

  Future<void> _insertarRelaciones(int promocionId, Promocion entidad) async {
    for (final id in entidad.productoIds.toSet()) {
      await _db.customInsert(
        'INSERT OR IGNORE INTO promocion_productos '
        '(promocion_id, producto_id) VALUES (?, ?)',
        variables: [Variable.withInt(promocionId), Variable.withInt(id)],
      );
    }

    for (final id in entidad.categoriaIds.toSet()) {
      await _db.customInsert(
        'INSERT OR IGNORE INTO promocion_categorias '
        '(promocion_id, categoria_id) VALUES (?, ?)',
        variables: [Variable.withInt(promocionId), Variable.withInt(id)],
      );
    }
  }

  Future<void> _eliminarRelaciones(int id) async {
    await _db.customUpdate(
      'DELETE FROM promocion_productos WHERE promocion_id = ?',
      variables: [Variable.withInt(id)],
    );
    await _db.customUpdate(
      'DELETE FROM promocion_categorias WHERE promocion_id = ?',
      variables: [Variable.withInt(id)],
    );
  }

  Future<int> registrar(Promocion entidad) {
    return _db.transaction(() async {
      final id = await _db.customInsert(
        '''
        INSERT INTO promociones_comerciales (
          nombre, descripcion, tipo, valor, fecha_inicio, fecha_fin,
          activa, minimo_cantidad, minimo_monto
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        variables: [
          Variable.withString(entidad.nombre),
          Variable.withString(entidad.descripcion),
          Variable.withString(entidad.tipo),
          Variable.withReal(entidad.valor),
          Variable<String>(entidad.fechaInicio?.toIso8601String()),
          Variable<String>(entidad.fechaFin?.toIso8601String()),
          Variable.withInt(entidad.activa ? 1 : 0),
          Variable<int>(entidad.minimoCantidad),
          Variable<double>(entidad.minimoMonto),
        ],
      );

      await _insertarRelaciones(id, entidad);
      return id;
    });
  }

  Future<bool> modificar(Promocion entidad) {
    return _db.transaction(() async {
      final filas = await _db.customUpdate(
        '''
        UPDATE promociones_comerciales
        SET nombre = ?, descripcion = ?, tipo = ?, valor = ?,
            fecha_inicio = ?, fecha_fin = ?, activa = ?,
            minimo_cantidad = ?, minimo_monto = ?
        WHERE id = ?
        ''',
        variables: [
          Variable.withString(entidad.nombre),
          Variable.withString(entidad.descripcion),
          Variable.withString(entidad.tipo),
          Variable.withReal(entidad.valor),
          Variable<String>(entidad.fechaInicio?.toIso8601String()),
          Variable<String>(entidad.fechaFin?.toIso8601String()),
          Variable.withInt(entidad.activa ? 1 : 0),
          Variable<int>(entidad.minimoCantidad),
          Variable<double>(entidad.minimoMonto),
          Variable.withInt(entidad.id),
        ],
      );

      if (filas == 0) return false;

      await _eliminarRelaciones(entidad.id);
      await _insertarRelaciones(entidad.id, entidad);
      return true;
    });
  }

  Future<void> eliminar(int id) {
    return _db.transaction(() async {
      await _eliminarRelaciones(id);
      await _db.customUpdate(
        'DELETE FROM promociones_comerciales WHERE id = ?',
        variables: [Variable.withInt(id)],
      );
    });
  }
}
