import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/facturacion/data/dao/secuencias_ncf_table.dart';

part 'secuencias_ncf_dao.g.dart';

@DriftAccessor(tables: [SecuenciasNcfTable])
class SecuenciasNcfDao extends DatabaseAccessor<AppDatabase>
    with _$SecuenciasNcfDaoMixin {
  SecuenciasNcfDao(super.db);

  Future<List<SecuenciasNcfTableData>> listar() {
    return (select(
      secuenciasNcfTable,
    )..orderBy([(t) => OrderingTerm.asc(t.tipo)])).get();
  }

  Future<SecuenciasNcfTableData?> porTipo(String tipo) {
    return (select(secuenciasNcfTable)
          ..where((t) => t.tipo.equals(tipo))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> asegurarDefaults() async {
    for (final tipo in const ['B01', 'B02', 'B04']) {
      final existe = await porTipo(tipo);
      if (existe != null) continue;
      await into(secuenciasNcfTable).insert(
        SecuenciasNcfTableCompanion.insert(
          tipo: tipo,
          prefijo: tipo,
          secuenciaActual: const Value(0),
          secuenciaDesde: const Value(1),
          secuenciaHasta: const Value(99999999),
          activo: const Value(true),
        ),
      );
    }
  }

  Future<void> guardar({
    required String tipo,
    required String prefijo,
    required int secuenciaActual,
    required int secuenciaDesde,
    required int secuenciaHasta,
    required bool activo,
  }) async {
    final row = await porTipo(tipo);
    final companion = SecuenciasNcfTableCompanion(
      tipo: Value(tipo),
      prefijo: Value(prefijo),
      secuenciaActual: Value(secuenciaActual),
      secuenciaDesde: Value(secuenciaDesde),
      secuenciaHasta: Value(secuenciaHasta),
      activo: Value(activo),
      actualizadoEn: Value(DateTime.now()),
    );
    if (row == null) {
      await into(secuenciasNcfTable).insert(companion);
    } else {
      await (update(
        secuenciasNcfTable,
      )..where((t) => t.id.equals(row.id))).write(companion);
    }
  }

  /// Reserva y devuelve el siguiente NCF completo (ej. B0100000001).
  Future<String> siguienteNcf(String tipo) async {
    return transaction(() async {
      await asegurarDefaults();
      final row = await porTipo(tipo);
      if (row == null) {
        throw StateError('No hay secuencia configurada para $tipo');
      }
      if (!row.activo) {
        throw StateError('Secuencia $tipo inactiva');
      }
      final siguiente = row.secuenciaActual + 1;
      if (siguiente < row.secuenciaDesde) {
        throw StateError(
          'Secuencia $tipo por debajo del mínimo (${row.secuenciaDesde})',
        );
      }
      if (siguiente > row.secuenciaHasta) {
        throw StateError(
          'Secuencia $tipo agotada (hasta ${row.secuenciaHasta})',
        );
      }
      await (update(
        secuenciasNcfTable,
      )..where((t) => t.id.equals(row.id))).write(
        SecuenciasNcfTableCompanion(
          secuenciaActual: Value(siguiente),
          actualizadoEn: Value(DateTime.now()),
        ),
      );
      final digitos = siguiente.toString().padLeft(8, '0');
      return '${row.prefijo}$digitos';
    });
  }
}
