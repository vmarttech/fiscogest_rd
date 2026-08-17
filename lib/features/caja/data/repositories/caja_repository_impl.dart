import 'package:fiscogest_rd/features/caja/domain/repositories/i_caja_repository.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/caja_movimientos_dao.dart';

class CajaRepositoryImpl implements ICajaRepository {

  CajaRepositoryImpl({required this.cajaMovimientosDao});
  final CajaMovimientosDao cajaMovimientosDao;

  @override
  Future<double?> obtenerSaldoActual() async {
    throw UnimplementedError('obtenerSaldoActual: Último saldo registrado en caja');
  }

  @override
  Future<void> registrarMovimiento({
    required String referencia,
    required double monto,
    required String tipo,
    required String descripcion,
  }) async {
    throw UnimplementedError('registrarMovimiento: Calcular saldo_anterior → nuevo_saldo = anterior ± monto');
  }
}
