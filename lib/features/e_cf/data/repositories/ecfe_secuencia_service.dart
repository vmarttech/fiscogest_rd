import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/tipo_ecf.dart';

class EcfeSecuenciaService {
  EcfeSecuenciaService(this._db);
  final AppDatabase _db;

  Future<({String encf, DateTime? vencimiento})> siguiente(TipoEcf tipo) async {
    final rows = await (_db.select(_db.ecfeSecuenciasTable)
          ..where((t) => t.tipoEcf.equals(tipo.codigo) & t.activo.equals(true))
          ..limit(1))
        .get();

    if (rows.isEmpty) {
      await _db.into(_db.ecfeSecuenciasTable).insert(
            EcfeSecuenciasTableCompanion.insert(
              tipoEcf: tipo.codigo,
              secuenciaActual: const Value(0),
              secuenciaDesde: const Value(1),
              secuenciaHasta: const Value(9999999999),
              fechaVencimiento:
                  Value(DateTime(DateTime.now().year + 1, 12, 31)),
              activo: const Value(true),
            ),
          );
      return siguiente(tipo);
    }

    final r = rows.first;
    final next = r.secuenciaActual + 1;
    if (next > r.secuenciaHasta) {
      throw StateError('Secuencia e-NCF agotada para tipo ${tipo.codigo}');
    }
    await (_db.update(_db.ecfeSecuenciasTable)..where((t) => t.id.equals(r.id)))
        .write(EcfeSecuenciasTableCompanion(secuenciaActual: Value(next)));

    return (
      encf: 'E${tipo.codigo}${next.toString().padLeft(10, '0')}',
      vencimiento: r.fechaVencimiento,
    );
  }
}
