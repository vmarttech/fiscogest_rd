import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/caja_movimientos_table.dart';

part 'caja_movimientos_dao.g.dart';

@DriftAccessor(tables: [CajaMovimientosTable])
class CajaMovimientosDao extends DatabaseAccessor<AppDatabase> with _$CajaMovimientosDaoMixin {
  CajaMovimientosDao(super.db);

  Future<List<CajaMovimientoData>> obtenerTodos() => select(cajaMovimientosTable).get();

  Future<List<CajaMovimientoData>> obtenerPorFecha(DateTime fecha) {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = inicio.add(const Duration(days: 1));
    return (select(cajaMovimientosTable)
      ..where((t) => t.fecha.isBiggerOrEqualValue(inicio))
      ..where((t) => t.fecha.isSmallerThanValue(fin))
      ..orderBy([(t) => OrderingTerm(expression: t.fecha, mode: OrderingMode.desc)])
    ).get();
  }

  Future<List<CajaMovimientoData>> obtenerPorRango(DateTime desde, DateTime hasta) =>
      (select(cajaMovimientosTable)
        ..where((t) => t.fecha.isBiggerOrEqualValue(desde))
        ..where((t) => t.fecha.isSmallerOrEqualValue(hasta))
        ..orderBy([(t) => OrderingTerm(expression: t.fecha, mode: OrderingMode.desc)])
      ).get();

  Future<CajaMovimientoData?> obtenerUltimoMovimiento() =>
      (select(cajaMovimientosTable)
        ..orderBy([(t) => OrderingTerm(expression: t.fecha, mode: OrderingMode.desc)])
        ..limit(1)
      ).getSingleOrNull();

  Future<double?> obtenerSaldoActual() async {
    final ultimo = await obtenerUltimoMovimiento();
    return ultimo?.saldoNuevo;
  }

  Future<int> registrarMovimiento(CajaMovimientosTableCompanion movimiento) =>
      into(cajaMovimientosTable).insert(movimiento);
}
