import 'package:fiscogest_rd/features/caja/domain/repositories/i_caja_repository.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_pagar_dao.dart';

class RegistrarAbonoUseCase {
  RegistrarAbonoUseCase({
    required this.cuentasPagarDao,
    this.cajaRepository,
  });

  final CuentasPagarDao cuentasPagarDao;
  final ICajaRepository? cajaRepository;

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

    final id = await cuentasPagarDao.registrarAbono(
      cuentaPagarId: cuentaPagarId,
      proveedorId: proveedorId,
      monto: monto,
      fechaPago: fecha,
      formaPago: formaPago,
      referencia: referencia,
      nota: nota,
    );

    // Dinero real sale de caja (efectivo / tarjeta / transfer / cheque).
    // Crédito u otro medio no físico: no mueve cajón.
    final caja = cajaRepository;
    final fp = formaPago.toLowerCase();
    final mueveCaja = caja != null &&
        (fp.contains('efectivo') ||
            fp.contains('tarjeta') ||
            fp.contains('transfer') ||
            fp.contains('cheque'));

    if (mueveCaja) {
      final sesion = await caja.obtenerSesionAbierta();
      if (sesion == null) {
        throw StateError(
          'Hay que abrir Caja antes de registrar un pago a proveedor con $formaPago',
        );
      }
      await caja.registrarMovimiento(
        referencia: 'PAGO-PROV-$cuentaPagarId',
        monto: monto,
        tipo: 'egreso',
        descripcion:
            'Pago proveedor #$proveedorId cuenta #$cuentaPagarId ${nota ?? ''}',
        formaPago: formaPago,
      );
    }

    return id;
  }
}
