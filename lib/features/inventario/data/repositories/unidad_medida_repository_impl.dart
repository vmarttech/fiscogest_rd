import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/unidad_medida.dart';
import 'package:fiscogest_rd/features/inventario/domain/repositories/unidad_medida_repository.dart';

class UnidadMedidaRepositoryImpl implements UnidadMedidaRepository {
  UnidadMedidaRepositoryImpl(this._db);
  final AppDatabase _db;

  UnidadMedida _map(UnidadMedidaData d) => UnidadMedida(
        id: d.id,
        nombre: d.nombre,
        abreviatura: d.abreviatura,
        descripcion: d.descripcion,
        codigo: d.codigo,
        factorABase: d.factorABase,
        esBase: d.esBase,
        activo: d.activo,
        creadoEn: d.creadoEn,
        actualizadoEn: d.actualizadoEn,
      );

  @override
  Future<List<UnidadMedida>> obtenerTodos() async {
    final datos = await _db.select(_db.unidadesMedida).get();
    return datos.map(_map).toList();
  }

  @override
  Future<UnidadMedida?> obtenerPorId(int id) async {
    final d = await (_db.select(_db.unidadesMedida)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return d == null ? null : _map(d);
  }

  @override
  Future<void> guardar(UnidadMedida unidad) async {
    await _db.into(_db.unidadesMedida).insert(
          UnidadesMedidaCompanion(
            nombre: Value(unidad.nombre),
            abreviatura: Value(unidad.abreviatura),
            descripcion: Value(unidad.descripcion),
            codigo: Value(unidad.codigo),
            factorABase: Value(unidad.factorABase),
            esBase: Value(unidad.esBase),
            activo: Value(unidad.activo),
            creadoEn: Value(unidad.creadoEn),
          ),
        );
  }

  @override
  Future<void> actualizar(UnidadMedida unidad) async {
    await (_db.update(_db.unidadesMedida)
          ..where((t) => t.id.equals(unidad.id!)))
        .write(
      UnidadesMedidaCompanion(
        nombre: Value(unidad.nombre),
        abreviatura: Value(unidad.abreviatura),
        descripcion: Value(unidad.descripcion),
        codigo: Value(unidad.codigo),
        factorABase: Value(unidad.factorABase),
        esBase: Value(unidad.esBase),
        activo: Value(unidad.activo),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> eliminar(int id) async {
    await (_db.delete(_db.unidadesMedida)..where((t) => t.id.equals(id))).go();
  }
}
