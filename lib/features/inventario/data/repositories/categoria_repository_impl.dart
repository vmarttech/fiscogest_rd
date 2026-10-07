import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/categoria.dart';
import 'package:fiscogest_rd/features/inventario/domain/repositories/categoria_repository.dart';

class CategoriaRepositoryImpl implements CategoriaRepository {
  CategoriaRepositoryImpl(this._db);
  final AppDatabase _db;

  Categoria _map(CategoriaData d) => Categoria(
        id: d.id,
        nombre: d.nombre,
        descripcion: d.descripcion,
        codigo: d.codigo,
        padreId: d.padreId,
        itbisPorCiento: d.itbisPorCiento,
        activo: d.activo,
        creadoEn: d.creadoEn,
        actualizadoEn: d.actualizadoEn,
      );

  @override
  Future<List<Categoria>> obtenerTodos() async {
    final datos = await _db.select(_db.categorias).get();
    return datos.map(_map).toList();
  }

  @override
  Future<Categoria?> obtenerPorId(int id) async {
    final d = await (_db.select(_db.categorias)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return d == null ? null : _map(d);
  }

  @override
  Future<void> guardar(Categoria categoria) async {
    await _db.into(_db.categorias).insert(
          CategoriasCompanion(
            nombre: Value(categoria.nombre),
            descripcion: Value(categoria.descripcion),
            codigo: Value(categoria.codigo),
            padreId: Value(categoria.padreId),
            itbisPorCiento: Value(categoria.itbisPorCiento),
            activo: Value(categoria.activo),
            creadoEn: Value(categoria.creadoEn),
          ),
        );
  }

  @override
  Future<void> actualizar(Categoria categoria) async {
    await (_db.update(_db.categorias)
          ..where((t) => t.id.equals(categoria.id!)))
        .write(
      CategoriasCompanion(
        nombre: Value(categoria.nombre),
        descripcion: Value(categoria.descripcion),
        codigo: Value(categoria.codigo),
        padreId: Value(categoria.padreId),
        itbisPorCiento: Value(categoria.itbisPorCiento),
        activo: Value(categoria.activo),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> eliminar(int id) async {
    await (_db.delete(_db.categorias)..where((t) => t.id.equals(id))).go();
  }
}
