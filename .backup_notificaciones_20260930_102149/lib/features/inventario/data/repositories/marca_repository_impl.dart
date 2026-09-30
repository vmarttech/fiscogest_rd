import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/marca.dart';
import 'package:fiscogest_rd/features/inventario/domain/repositories/marca_repository.dart';

class MarcaRepositoryImpl implements MarcaRepository {
  MarcaRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<List<Marca>> obtenerTodos() async {
    final datos = await _db.select(_db.marcas).get();
    return datos
        .map(
          (d) => Marca(
            id: d.id,
            nombre: d.nombre,
            descripcion: d.descripcion,
            creadoEn: d.creadoEn,
            actualizadoEn: d.actualizadoEn,
          ),
        )
        .toList();
  }

  @override
  Future<Marca?> obtenerPorId(int id) async {
    final d = await (_db.select(
      _db.marcas,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (d == null) return null;
    return Marca(
      id: d.id,
      nombre: d.nombre,
      descripcion: d.descripcion,
      creadoEn: d.creadoEn,
      actualizadoEn: d.actualizadoEn,
    );
  }

  @override
  Future<void> guardar(Marca marca) async {
    await _db
        .into(_db.marcas)
        .insert(
          MarcasCompanion(
            nombre: Value(marca.nombre),
            descripcion: Value(marca.descripcion),
            creadoEn: Value(marca.creadoEn),
          ),
        );
  }

  @override
  Future<void> actualizar(Marca marca) async {
    await (_db.update(_db.marcas)..where((t) => t.id.equals(marca.id!))).write(
      MarcasCompanion(
        nombre: Value(marca.nombre),
        descripcion: Value(marca.descripcion),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> eliminar(int id) async {
    await (_db.delete(_db.marcas)..where((t) => t.id.equals(id))).go();
  }
}
