import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/existencia.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_existencia_repository.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/existencias_table.dart';

class ExistenciaRepositoryImpl implements IExistenciaRepository {
  ExistenciaRepositoryImpl(this._db);
  // ✅ Constructor primero: soluciona aviso orden
  final AppDatabase _db;

  @override
  Future<Existencia?> obtenerPorProducto(int productoId) async {
    final registro =
        await (_db.select(_db.existenciasTable)..where(
              (ExistenciasTable tbl) => tbl.productoId.equals(productoId),
            ))
            .getSingleOrNull();
    return registro != null ? _mapearAEntidad(registro) : null;
  }

  @override
  Future<int> crear(Existencia existencia) async {
    if (existencia.existenciaActual < 0 ||
        existencia.existenciaDisponible < 0 ||
        existencia.existenciaDisponible > existencia.existenciaActual) {
      throw Exception(
        'Valores inválidos: cantidades ≥ 0 y disponible ≤ actual',
      );
    }
    return await _db
        .into(_db.existenciasTable)
        .insert(
          ExistenciasTableCompanion(
            productoId: Value(existencia.productoId),
            existenciaActual: Value(existencia.existenciaActual),
            existenciaDisponible: Value(existencia.existenciaDisponible),
          ),
        );
  }

  @override
  Future<bool> actualizar(Existencia existencia) async {
    if (existencia.id == null) return false;
    if (existencia.existenciaActual < 0 ||
        existencia.existenciaDisponible < 0 ||
        existencia.existenciaDisponible > existencia.existenciaActual) {
      throw Exception('No se permite negativos ni disponible mayor a actual');
    }
    // ✅ CORREGIDO CLAVE: Drift replace devuelve bool
    final bool actualizado = await _db
        .update(_db.existenciasTable)
        .replace(
          ExistenciasTableCompanion(
            id: Value(existencia.id!),
            productoId: Value(existencia.productoId),
            existenciaActual: Value(existencia.existenciaActual),
            existenciaDisponible: Value(existencia.existenciaDisponible),
          ),
        );
    return actualizado;
  }

  @override
  Future<List<Existencia>> obtenerTodas() async {
    final List<ExistenciaData> listaDatos = await _db
        .select(_db.existenciasTable)
        .get();
    return listaDatos.map(_mapearAEntidad).toList();
  }

  Existencia _mapearAEntidad(ExistenciaData datos) {
    return Existencia(
      id: datos.id,
      productoId: datos.productoId,
      existenciaActual: datos.existenciaActual,
      existenciaDisponible: datos.existenciaDisponible,
    );
  }
}
