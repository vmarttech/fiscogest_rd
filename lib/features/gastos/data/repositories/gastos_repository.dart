import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/gastos/domain/entities/gasto.dart';

class GastosRepository {
  GastosRepository(this._db);
  final AppDatabase _db;

  Future<List<Gasto>> listar({DateTime? desde, DateTime? hasta}) async {
    final conditions = <String>[];
    final vars = <Variable>[];
    if (desde != null) {
      conditions.add('fecha >= ?');
      vars.add(Variable.withString(desde.toIso8601String()));
    }
    if (hasta != null) {
      conditions.add('fecha < ?');
      vars.add(Variable.withString(hasta.toIso8601String()));
    }
    final where =
        conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final rows = await _db.customSelect(
      '''
      SELECT id, fecha, categoria, descripcion, monto, forma_pago, notas,
             creado_en, actualizado_en
      FROM gastos_table
      $where
      ORDER BY fecha DESC, id DESC
      ''',
      variables: vars,
      readsFrom: {_db.gastosTable},
    ).get();

    DateTime parseDt(dynamic v) {
      if (v is DateTime) return v;
      return DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();
    }

    return rows.map((r) {
      return Gasto(
        id: (r.data['id'] as num?)?.toInt(),
        fecha: parseDt(r.data['fecha']),
        categoria: r.data['categoria']?.toString() ?? 'General',
        descripcion: r.data['descripcion']?.toString() ?? '',
        monto: (r.data['monto'] as num?)?.toDouble() ?? 0,
        formaPago: r.data['forma_pago']?.toString() ?? 'efectivo',
        notas: r.data['notas']?.toString(),
        creadoEn: parseDt(r.data['creado_en']),
        actualizadoEn: r.data['actualizado_en'] == null
            ? null
            : parseDt(r.data['actualizado_en']),
      );
    }).toList();
  }

  Future<int> guardar(Gasto g) async {
    if (g.id == null) {
      final row = await _db.into(_db.gastosTable).insertReturning(
            GastosTableCompanion.insert(
              fecha: g.fecha,
              categoria: Value(g.categoria),
              descripcion: g.descripcion,
              monto: g.monto,
              formaPago: Value(g.formaPago),
              notas: Value(g.notas),
              creadoEn: g.creadoEn,
              actualizadoEn: Value(g.actualizadoEn),
            ),
          );
      return row.id;
    }
    await (_db.update(_db.gastosTable)..where((t) => t.id.equals(g.id!)))
        .write(
      GastosTableCompanion(
        fecha: Value(g.fecha),
        categoria: Value(g.categoria),
        descripcion: Value(g.descripcion),
        monto: Value(g.monto),
        formaPago: Value(g.formaPago),
        notas: Value(g.notas),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
    return g.id!;
  }

  Future<void> eliminar(int id) async {
    await (_db.delete(_db.gastosTable)..where((t) => t.id.equals(id))).go();
  }
}
