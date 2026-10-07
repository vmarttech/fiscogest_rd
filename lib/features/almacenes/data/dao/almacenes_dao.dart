import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/almacenes/domain/entities/almacen.dart';

class AlmacenesDao {
  AlmacenesDao(this._db);
  final AppDatabase _db;

  Almacen _map(AlmacenData r, {double stockTotal = 0, int skus = 0}) => Almacen(
        id: r.id,
        codigo: r.codigo,
        nombre: r.nombre,
        tipo: TipoAlmacenX.fromStorage(r.tipo),
        direccion: r.direccion,
        telefono: r.telefono,
        responsable: r.responsable,
        activo: r.activo,
        creadoEn: r.creadoEn,
        actualizadoEn: r.actualizadoEn,
        stockTotal: stockTotal,
        skus: skus,
      );

  Future<List<Almacen>> obtenerTodos({bool soloActivos = false}) async {
    final q = _db.select(_db.almacenesTable)
      ..orderBy([
        (t) => OrderingTerm.desc(t.tipo.equals('principal')),
        (t) => OrderingTerm.asc(t.nombre),
      ]);
    if (soloActivos) q.where((t) => t.activo.equals(true));
    final rows = await q.get();
    final out = <Almacen>[];
    for (final r in rows) {
      final stats = await _stats(r.id);
      out.add(_map(r, stockTotal: stats.$1, skus: stats.$2));
    }
    return out;
  }

  Future<(double, int)> _stats(int almacenId) async {
    final rows = await (_db.select(_db.stockAlmacenTable)
          ..where((t) => t.almacenId.equals(almacenId)))
        .get();
    var total = 0.0;
    var skus = 0;
    for (final r in rows) {
      if (r.cantidad.abs() > 0.0001) {
        total += r.cantidad;
        skus++;
      }
    }
    return (total, skus);
  }

  Future<int> contarActivos() async {
    final rows = await (_db.select(_db.almacenesTable)
          ..where((t) => t.activo.equals(true)))
        .get();
    return rows.length;
  }

  Future<bool> codigoOcupado(String codigo, {int? exceptId}) async {
    final q = _db.select(_db.almacenesTable)
      ..where((t) => t.codigo.lower().equals(codigo.trim().toLowerCase()));
    final rows = await q.get();
    return rows.any((r) => r.id != exceptId);
  }

  Future<int> insertar(Almacen a) async {
    if (await codigoOcupado(a.codigo)) {
      throw Exception('Ya existe un almacén con el código ${a.codigo}.');
    }
    if (a.tipo == TipoAlmacen.principal) {
      await _quitarPrincipal();
    }
    return _db.into(_db.almacenesTable).insert(
          AlmacenesTableCompanion.insert(
            codigo: a.codigo.trim(),
            nombre: a.nombre.trim(),
            tipo: Value(a.tipo.name),
            direccion: Value(a.direccion?.trim()),
            telefono: Value(a.telefono?.trim()),
            responsable: Value(a.responsable?.trim()),
            activo: Value(a.activo),
          ),
        );
  }

  Future<void> actualizar(Almacen a) async {
    if (a.id == null) return;
    if (await codigoOcupado(a.codigo, exceptId: a.id)) {
      throw Exception('Ya existe un almacén con el código ${a.codigo}.');
    }
    if (!a.activo) {
      final n = await contarActivos();
      final actual = await obtenerPorId(a.id!);
      if (n <= 1 && (actual?.activo ?? false)) {
        throw Exception('No puedes desactivar el último almacén activo.');
      }
    }
    if (a.tipo == TipoAlmacen.principal) {
      await _quitarPrincipal(exceptId: a.id);
    }
    await (_db.update(_db.almacenesTable)..where((t) => t.id.equals(a.id!)))
        .write(
      AlmacenesTableCompanion(
        codigo: Value(a.codigo.trim()),
        nombre: Value(a.nombre.trim()),
        tipo: Value(a.tipo.name),
        direccion: Value(a.direccion?.trim()),
        telefono: Value(a.telefono?.trim()),
        responsable: Value(a.responsable?.trim()),
        activo: Value(a.activo),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }

  Future<Almacen?> obtenerPorId(int id) async {
    final r = await (_db.select(_db.almacenesTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (r == null) return null;
    final stats = await _stats(id);
    return _map(r, stockTotal: stats.$1, skus: stats.$2);
  }

  Future<void> _quitarPrincipal({int? exceptId}) async {
    final rows = await (_db.select(_db.almacenesTable)
          ..where((t) => t.tipo.equals('principal')))
        .get();
    for (final r in rows) {
      if (exceptId != null && r.id == exceptId) continue;
      await (_db.update(_db.almacenesTable)..where((t) => t.id.equals(r.id)))
          .write(
        AlmacenesTableCompanion(
          tipo: const Value('tienda'),
          actualizadoEn: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> marcarPrincipal(int id) async {
    await _quitarPrincipal();
    await (_db.update(_db.almacenesTable)..where((t) => t.id.equals(id))).write(
      AlmacenesTableCompanion(
        tipo: const Value('principal'),
        activo: const Value(true),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }

  Future<void> asegurarPrincipal() async {
    final todos = await (_db.select(_db.almacenesTable)).get();
    if (todos.isNotEmpty) return;
    await insertar(
      const Almacen(
        codigo: 'ALM-01',
        nombre: 'Almacén principal',
        tipo: TipoAlmacen.principal,
        activo: true,
      ),
    );
  }
}
