import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/categoria.dart';
import 'package:fiscogest_rd/features/inventario/domain/repositories/categoria_repository.dart';

class CategoriaRepositoryImpl implements CategoriaRepository {

  CategoriaRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<List<Categoria>> obtenerTodos() async {
    final datos = await _db.select(_db.categorias).get();
    return datos.map((d) => Categoria(
      id: d.id,
      nombre: d.nombre,
      descripcion: d.descripcion,
      creadoEn: d.creadoEn,
      actualizadoEn: d.actualizadoEn,
    )).toList();
  }

  @override
  Future<Categoria?> obtenerPorId(int id) async {
    final d = await (_db.select(_db.categorias)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (d == null) return null;
    return Categoria(
      id: d.id,
      nombre: d.nombre,
      descripcion: d.descripcion,
      creadoEn: d.creadoEn,
      actualizadoEn: d.actualizadoEn,
    );
  }

  @override
  Future<void> guardar(Categoria categoria) async {
    await _db.into(_db.categorias).insert(CategoriasCompanion(
      nombre: Value(categoria.nombre),
      descripcion: Value(categoria.descripcion),
      creadoEn: Value(categoria.creadoEn),
    ));
  }

  @override
  Future<void> actualizar(Categoria categoria) async {
    await (_db.update(_db.categorias)
      ..where((t) => t.id.equals(categoria.id!))
    ).write(CategoriasCompanion(
      nombre: Value(categoria.nombre),
      descripcion: Value(categoria.descripcion),
      actualizadoEn: Value(DateTime.now()),
    ));
  }

  @override
  Future<void> eliminar(int id) async {
    await (_db.delete(_db.categorias)..where((t) => t.id.equals(id))).go();
  }
}
