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
          'SELECT $_columnas FROM promociones_comerciales WHERE activa = 1 ORDER BY id DESC',
        )
        .get();
    return filas.map((fila) => fila.data).toList();
  }

  Future<Map<String, dynamic>?> buscarPorId(int id) async {
    final filas = await _db
        .customSelect(
          'SELECT $_columnas FROM promociones_comerciales WHERE id = ? LIMIT 1',
          variables: [Variable.withInt(id)],
        )
        .get();
    return filas.isEmpty ? null : filas.first.data;
  }

  Future<int> registrar(Promocion entidad) async {
    return _db.customInsert(
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
  }

  Future<bool> modificar(Promocion entidad) async {
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
    return filas > 0;
  }

  Future<void> eliminar(int id) async {
    await _db.customUpdate(
      'DELETE FROM promociones_comerciales WHERE id = ?',
      variables: [Variable.withInt(id)],
    );
  }
}
