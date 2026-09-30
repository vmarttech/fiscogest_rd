import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/caja_sesiones_table.dart';

part 'caja_sesiones_dao.g.dart';

@DriftAccessor(tables: [CajaSesionesTable])
class CajaSesionesDao extends DatabaseAccessor<AppDatabase>
    with _$CajaSesionesDaoMixin {
  CajaSesionesDao(super.db);

  Future<CajaSesionData?> obtenerSesionAbierta() {
    return (select(cajaSesionesTable)
          ..where((t) => t.estado.equals('abierta'))
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.fechaApertura,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> abrirSesion({required double fondoInicial, int usuarioId = 1}) {
    return into(cajaSesionesTable).insert(
      CajaSesionesTableCompanion.insert(
        fechaApertura: DateTime.now(),
        fondoInicial: fondoInicial,
        usuarioId: Value(usuarioId),
        estado: const Value('abierta'),
      ),
    );
  }

  Future<bool> cerrarSesion({
    required int sesionId,
    required double saldoTeorico,
    required double montoContado,
    String? observacion,
  }) async {
    final diferencia = montoContado - saldoTeorico;
    final n =
        await (update(
          cajaSesionesTable,
        )..where((t) => t.id.equals(sesionId))).write(
          CajaSesionesTableCompanion(
            estado: const Value('cerrada'),
            fechaCierre: Value(DateTime.now()),
            saldoTeorico: Value(saldoTeorico),
            montoContado: Value(montoContado),
            diferencia: Value(diferencia),
            observacion: Value(observacion),
          ),
        );
    return n > 0;
  }

  Future<CajaSesionData?> obtenerPorId(int id) {
    return (select(
      cajaSesionesTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }
}
