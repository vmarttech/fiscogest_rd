import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/creditos/data/dao/pronto_pago_acuerdos_table.dart';

part 'pronto_pago_acuerdos_dao.g.dart';

@DriftAccessor(tables: [ProntoPagoAcuerdosTable])
class ProntoPagoAcuerdosDao extends DatabaseAccessor<AppDatabase>
    with _$ProntoPagoAcuerdosDaoMixin {
  ProntoPagoAcuerdosDao(super.db);

  Future<ProntoPagoAcuerdoData?> activoPorCuenta(int cuentaId) {
    return (select(prontoPagoAcuerdosTable)
          ..where((t) => t.cuentaId.equals(cuentaId) & t.estado.equals('activo'))
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<ProntoPagoAcuerdoData>> historialPorCuenta(int cuentaId) {
    return (select(prontoPagoAcuerdosTable)
          ..where((t) => t.cuentaId.equals(cuentaId))
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .get();
  }

  /// Cancela acuerdos activos previos e inserta uno nuevo.
  Future<int> guardarAcuerdo({
    required int cuentaId,
    required double capitalPendiente,
    required double interesPendiente,
    required double descuentoInteresPct,
    required double descuentoMonto,
    required double interesTrasDescuento,
    required double montoLiquidacion,
    required int cuotasPendientes,
    String notas = '',
    int? usuarioId,
  }) async {
    return transaction(() async {
      await (update(prontoPagoAcuerdosTable)
            ..where(
              (t) => t.cuentaId.equals(cuentaId) & t.estado.equals('activo'),
            ))
          .write(const ProntoPagoAcuerdosTableCompanion(estado: Value('cancelado')));

      return into(prontoPagoAcuerdosTable).insert(
        ProntoPagoAcuerdosTableCompanion.insert(
          cuentaId: cuentaId,
          capitalPendiente: capitalPendiente,
          interesPendiente: interesPendiente,
          descuentoInteresPct: Value(descuentoInteresPct),
          descuentoMonto: Value(descuentoMonto),
          interesTrasDescuento: interesTrasDescuento,
          montoLiquidacion: montoLiquidacion,
          cuotasPendientes: Value(cuotasPendientes),
          notas: Value(notas),
          usuarioId: Value(usuarioId),
          estado: const Value('activo'),
        ),
      );
    });
  }

  Future<void> cancelarActivo(int cuentaId) async {
    await (update(prontoPagoAcuerdosTable)
          ..where(
            (t) => t.cuentaId.equals(cuentaId) & t.estado.equals('activo'),
          ))
        .write(const ProntoPagoAcuerdosTableCompanion(estado: Value('cancelado')));
  }

  Future<void> marcarAplicado(int acuerdoId) async {
    await (update(prontoPagoAcuerdosTable)
          ..where((t) => t.id.equals(acuerdoId)))
        .write(
      ProntoPagoAcuerdosTableCompanion(
        estado: const Value('aplicado'),
        aplicadoEn: Value(DateTime.now()),
      ),
    );
  }
}
