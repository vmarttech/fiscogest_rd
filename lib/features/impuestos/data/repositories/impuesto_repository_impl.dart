import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/impuestos/domain/entities/impuesto_entity.dart';

class ImpuestoRepositoryImpl {
  ImpuestoRepositoryImpl(this._db);
  final AppDatabase _db;

  ImpuestoEntity _map(ImpuestoData d) => ImpuestoEntity(
        id: d.id,
        codigo: d.codigo,
        nombre: d.nombre,
        porcentaje: d.porcentaje,
        tipo: d.tipo,
        esExento: d.esExento,
        esDefault: d.esDefault,
        activo: d.activo,
        descripcion: d.descripcion,
      );

  Future<void> _seedSiVacio() async {
    final rows = await _db.select(_db.impuestosTable).get();
    if (rows.isNotEmpty) return;
    const seed = [
      ImpuestoEntity(
        codigo: 'ITBIS-18',
        nombre: 'ITBIS 18%',
        porcentaje: 18,
        tipo: 'ITBIS',
        esExento: false,
        esDefault: true,
        descripcion: 'Tasa general DGII',
      ),
      ImpuestoEntity(
        codigo: 'ITBIS-16',
        nombre: 'ITBIS 16%',
        porcentaje: 16,
        tipo: 'ITBIS',
        esExento: false,
        descripcion: 'Tasa reducida DGII',
      ),
      ImpuestoEntity(
        codigo: 'EXENTO',
        nombre: 'ITBIS 0% (Exento)',
        porcentaje: 0,
        tipo: 'Exento',
        esExento: true,
        descripcion: 'Bienes y servicios exentos',
      ),
      ImpuestoEntity(
        codigo: 'PROPINA-10',
        nombre: 'Propina legal 10%',
        porcentaje: 10,
        tipo: 'Adicional',
        esExento: false,
        descripcion: 'Sector gastronómico / Ley 358-05',
      ),
    ];
    for (final i in seed) {
      await _insertRaw(i);
    }
  }

  Future<void> _insertRaw(ImpuestoEntity impuesto) async {
    await _db.into(_db.impuestosTable).insert(
          ImpuestosTableCompanion.insert(
            codigo: Value(impuesto.codigo.trim()),
            nombre: impuesto.nombre.trim(),
            porcentaje: impuesto.porcentaje,
            tipo: Value(impuesto.tipo),
            esExento: Value(impuesto.esExento),
            esDefault: Value(impuesto.esDefault),
            activo: Value(impuesto.activo),
            descripcion: Value(impuesto.descripcion),
          ),
        );
  }

  Future<void> _quitarOtrosDefault({int? exceptId, required String tipo}) async {
    final q = _db.update(_db.impuestosTable)
      ..where((t) {
        final cond = t.tipo.equals(tipo) & t.esDefault.equals(true);
        if (exceptId == null) return cond;
        return cond & t.id.isNotValue(exceptId);
      });
    await q.write(
      ImpuestosTableCompanion(
        esDefault: const Value(false),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }

  Future<List<ImpuestoEntity>> obtenerImpuestos() async {
    await _seedSiVacio();
    final rows = await (_db.select(_db.impuestosTable)
          ..orderBy([
            (t) => OrderingTerm.desc(t.esDefault),
            (t) => OrderingTerm.asc(t.tipo),
            (t) => OrderingTerm.asc(t.nombre),
          ]))
        .get();
    return rows.map(_map).toList();
  }

  Future<ImpuestoEntity?> obtenerDefaultItbis() async {
    await _seedSiVacio();
    final rows = await (_db.select(_db.impuestosTable)
          ..where(
            (t) =>
                t.tipo.equals('ITBIS') &
                t.esDefault.equals(true) &
                t.activo.equals(true),
          ))
        .get();
    if (rows.isNotEmpty) return _map(rows.first);
    final any = await (_db.select(_db.impuestosTable)
          ..where(
            (t) =>
                t.tipo.equals('ITBIS') &
                t.activo.equals(true) &
                t.esExento.equals(false),
          ))
        .get();
    return any.isEmpty ? null : _map(any.first);
  }

  Future<void> guardarImpuesto(ImpuestoEntity impuesto) async {
    if (impuesto.porcentaje < 0 || impuesto.porcentaje > 100) {
      throw Exception('El porcentaje debe estar entre 0 y 100.');
    }
    final nombre = impuesto.nombre.trim();
    final dup = await (_db.select(_db.impuestosTable)
          ..where((t) => t.nombre.lower().equals(nombre.toLowerCase())))
        .get();
    if (dup.isNotEmpty) {
      throw Exception('Ya existe un impuesto registrado con este nombre.');
    }
    final entity = impuesto.copyWith(nombre: nombre);
    if (entity.esDefault && entity.tipo == 'ITBIS') {
      await _quitarOtrosDefault(tipo: 'ITBIS');
    }
    await _insertRaw(entity);
  }

  Future<void> actualizarImpuesto(ImpuestoEntity impuesto) async {
    if (impuesto.id == null) return;
    if (impuesto.porcentaje < 0 || impuesto.porcentaje > 100) {
      throw Exception('El porcentaje debe estar entre 0 y 100.');
    }
    final nombre = impuesto.nombre.trim();
    final dup = await (_db.select(_db.impuestosTable)
          ..where(
            (t) =>
                t.nombre.lower().equals(nombre.toLowerCase()) &
                t.id.isNotValue(impuesto.id!),
          ))
        .get();
    if (dup.isNotEmpty) {
      throw Exception('Ya existe otro impuesto con este nombre.');
    }
    if (!impuesto.activo && impuesto.esDefault) {
      throw Exception('No puedes desactivar el ITBIS predeterminado.');
    }
    if (impuesto.esDefault && impuesto.tipo == 'ITBIS') {
      await _quitarOtrosDefault(exceptId: impuesto.id, tipo: 'ITBIS');
    }
    await (_db.update(_db.impuestosTable)
          ..where((t) => t.id.equals(impuesto.id!)))
        .write(
      ImpuestosTableCompanion(
        codigo: Value(impuesto.codigo.trim()),
        nombre: Value(nombre),
        porcentaje: Value(impuesto.porcentaje),
        tipo: Value(impuesto.tipo),
        esExento: Value(impuesto.esExento),
        esDefault: Value(impuesto.esDefault),
        activo: Value(impuesto.activo),
        descripcion: Value(impuesto.descripcion),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }

  Future<void> eliminarImpuesto(int id) async {
    final actual = await (_db.select(_db.impuestosTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (actual == null) return;
    if (actual.esDefault && actual.tipo == 'ITBIS') {
      throw Exception(
        'No puedes eliminar el ITBIS predeterminado. Marca otro como predeterminado primero.',
      );
    }
    await (_db.delete(_db.impuestosTable)..where((t) => t.id.equals(id))).go();
  }
}
