import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_pagar_dao.dart';

class RegistrarAbonoUseCase {
  RegistrarAbonoUseCase({required this.cuentasPagarDao});

  final CuentasPagarDao cuentasPagarDao;

  Future<int> call({
    required int cuentaPagarId,
    required int proveedorId,
    required double monto,
    DateTime? fechaPago,
    String formaPago = 'efectivo',
    String? referencia,
    String? nota,
  }) async {
    final fecha = fechaPago ?? DateTime.now();

    if (monto <= 0) {
      throw StateError('El monto del abono debe ser mayor a cero');
    }

    return await cuentasPagarDao.registrarAbono(
      cuentaPagarId: cuentaPagarId,
      proveedorId: proveedorId,
      monto: monto,
      fechaPago: fecha,
      formaPago: formaPago,
      referencia: referencia,
      nota: nota,
    );
  }
}
