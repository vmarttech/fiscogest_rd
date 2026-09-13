import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/caja/domain/repositories/i_caja_repository.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/caja_movimientos_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

class CajaRepositoryImpl implements ICajaRepository {
  CajaRepositoryImpl({required this.cajaMovimientosDao});
  final CajaMovimientosDao cajaMovimientosDao;

  @override
  Future<double?> obtenerSaldoActual() async {
    final ultimo = await cajaMovimientosDao.obtenerUltimoMovimiento();
    if (ultimo != null) {
      return ultimo.saldoNuevo;
    }
    return 0.0;
  }

  @override
  Future<void> registrarMovimiento({
    required String referencia,
    required double monto,
    required String tipo,
    required String descripcion,
  }) async {
    final saldoAnterior = await obtenerSaldoActual() ?? 0.0;
    late double saldoNuevo;
    late MovimientoCaja tipoMovimiento;
    if (tipo == 'ingreso' || tipo == 'entrada') {
      saldoNuevo = saldoAnterior + monto;
      tipoMovimiento = MovimientoCaja.ingreso;
    } else {
      saldoNuevo = saldoAnterior - monto;
      tipoMovimiento = MovimientoCaja.egreso;
    }
    await cajaMovimientosDao.registrarMovimiento(
      CajaMovimientosTableCompanion(
        tipo: Value(tipoMovimiento),
        referenciaTipo: const Value(ReferenciaTipo.compra),
        referenciaId: Value(int.tryParse(referencia.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0),
        monto: Value(monto),
        formaPago: const Value(FormaPago.efectivo),
        saldoAnterior: Value(saldoAnterior),
        saldoNuevo: Value(saldoNuevo),
      ),
    );
  }
}
