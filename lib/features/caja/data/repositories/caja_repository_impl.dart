import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/caja_movimientos_dao.dart';
import 'package:fiscogest_rd/features/caja/domain/repositories/i_caja_repository.dart';

class CajaRepositoryImpl implements ICajaRepository {
  CajaRepositoryImpl(this.cajaDao);

  final CajaMovimientosDao cajaDao;

  @override
  Future<void> registrarMovimiento({
    required String referencia,
    required double monto,
    required String tipo,
    required String descripcion,
  }) async {
    final ultimoSaldo = await cajaDao.obtenerSaldoActual() ?? 0.0;
    final nuevoSaldo = tipo == 'INGRESO' ? ultimoSaldo + monto : ultimoSaldo - monto;

    final companion = CajaMovimientosTableCompanion(
      tipo: Value(tipo),
      referenciaTipo: const Value('Ajuste'),
      referenciaId: const Value(0),
      monto: Value(monto),
      formaPago: const Value('Efectivo'),
      saldoAnterior: Value(ultimoSaldo),
      saldoNuevo: Value(nuevoSaldo),
      fecha: Value(DateTime.now()),
    );

    await cajaDao.registrarMovimiento(companion);
  }

  @override
  Future<double?> obtenerSaldoActual() async {
    return await cajaDao.obtenerSaldoActual();
  }
}
