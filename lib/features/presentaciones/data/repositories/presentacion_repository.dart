import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/presentaciones/domain/entities/presentacion.dart';

class PresentacionRepository {
  PresentacionRepository(this._db);
  final AppDatabase _db;

  Presentacion _map(PresentacionData d) => Presentacion(
        id: d.id,
        nombre: d.nombre,
        abreviatura: d.abreviatura,
        codigo: d.codigo,
        factorUnidades: d.factorUnidades,
        unidadMedidaId: d.unidadMedidaId,
        activo: d.activo,
      );

  Future<void> _seedSiVacio() async {
    final rows = await _db.select(_db.presentacionesTable).get();
    if (rows.isNotEmpty) return;
    for (final p in [
      Presentacion(nombre: 'Unidad', abreviatura: 'UND', codigo: 'UND', factorUnidades: 1),
      Presentacion(nombre: 'Caja', abreviatura: 'CAJ', codigo: 'CAJ', factorUnidades: 12),
      Presentacion(nombre: 'Kilogramo', abreviatura: 'KG', codigo: 'KG', factorUnidades: 1),
      Presentacion(nombre: 'Litro', abreviatura: 'LT', codigo: 'LT', factorUnidades: 1),
    ]) {
      await agregarPresentacion(p);
    }
  }

  Future<List<Presentacion>> obtenerPresentaciones() async {
    await _seedSiVacio();
    final rows = await (_db.select(_db.presentacionesTable)
          ..orderBy([(t) => OrderingTerm.asc(t.nombre)]))
        .get();
    return rows.map(_map).toList();
  }

  Future<void> agregarPresentacion(Presentacion presentacion) async {
    final nombre = presentacion.nombre.trim();
    final existe = await (_db.select(_db.presentacionesTable)
          ..where((t) => t.nombre.lower().equals(nombre.toLowerCase())))
        .get();
    if (existe.isNotEmpty) {
      throw Exception('Ya existe una presentación registrada con ese nombre.');
    }
    await _db.into(_db.presentacionesTable).insert(
          PresentacionesTableCompanion.insert(
            nombre: nombre,
            abreviatura: Value(presentacion.abreviatura.trim().toUpperCase()),
            codigo: Value(presentacion.codigo.trim()),
            factorUnidades: Value(presentacion.factorUnidades),
            unidadMedidaId: Value(presentacion.unidadMedidaId),
            activo: Value(presentacion.activo),
          ),
        );
  }

  Future<void> actualizarPresentacion(Presentacion presentacion) async {
    if (presentacion.id == null) return;
    final nombre = presentacion.nombre.trim();
    final dup = await (_db.select(_db.presentacionesTable)
          ..where(
            (t) =>
                t.nombre.lower().equals(nombre.toLowerCase()) &
                t.id.isNotValue(presentacion.id!),
          ))
        .get();
    if (dup.isNotEmpty) {
      throw Exception('Ya existe otra presentación con ese nombre.');
    }
    await (_db.update(_db.presentacionesTable)
          ..where((t) => t.id.equals(presentacion.id!)))
        .write(
      PresentacionesTableCompanion(
        nombre: Value(nombre),
        abreviatura: Value(presentacion.abreviatura.trim().toUpperCase()),
        codigo: Value(presentacion.codigo.trim()),
        factorUnidades: Value(presentacion.factorUnidades),
        unidadMedidaId: Value(presentacion.unidadMedidaId),
        activo: Value(presentacion.activo),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }

  Future<void> eliminarPresentacion(int id) async {
    await (_db.delete(_db.presentacionesTable)..where((t) => t.id.equals(id))).go();
  }
}
