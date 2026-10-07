import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/transferencias/domain/entities/transferencia.dart';

class TransferenciasDao {
  TransferenciasDao(this._db);
  final AppDatabase _db;

  Future<int> insertar(Transferencia t) {
    return _db.into(_db.transferenciasTable).insert(
          TransferenciasTableCompanion.insert(
            almacenOrigenId: t.almacenOrigenId,
            almacenDestinoId: t.almacenDestinoId,
            productoId: t.productoId,
            cantidad: t.cantidad,
            nota: Value(t.nota),
            fecha: Value(t.fecha),
            estado: Value(t.estado),
          ),
        );
  }

  Future<List<Transferencia>> ultimas({int limit = 40}) async {
    final q = _db.select(_db.transferenciasTable)
      ..orderBy([(t) => OrderingTerm.desc(t.fecha)])
      ..limit(limit);
    final rows = await q.get();
    final almacenes = {
      for (final a in await _db.select(_db.almacenesTable).get()) a.id: a.nombre
    };
    final productos = {
      for (final p in await _db.select(_db.productosTable).get())
        p.id: (p.codigo, p.nombre)
    };
    return [
      for (final r in rows)
        Transferencia(
          id: r.id,
          almacenOrigenId: r.almacenOrigenId,
          almacenDestinoId: r.almacenDestinoId,
          productoId: r.productoId,
          cantidad: r.cantidad,
          nota: r.nota,
          fecha: r.fecha,
          estado: r.estado,
          origenNombre: almacenes[r.almacenOrigenId],
          destinoNombre: almacenes[r.almacenDestinoId],
          productoCodigo: productos[r.productoId]?.$1,
          productoNombre: productos[r.productoId]?.$2,
        ),
    ];
  }
}
