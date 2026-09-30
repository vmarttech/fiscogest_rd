import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/cuenta_pagar.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/abono.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart';

final listadoCuentasPagarProvider =
    FutureProvider.autoDispose<List<CuentaPagar>>((Ref ref) async {
  final dao = ref.watch(cuentasPagarDaoProvider);
  final registros = await dao.listarCuentasPorPagar();

  return registros
      .map(
        (r) => CuentaPagar(
          id: r.cuenta.id,
          compraId: 0,
          nombreProveedor: r.nombreProveedor,
          numeroDocumento: r.cuenta.concepto,
          fechaEmision: r.cuenta.fechaEmision,
          fechaVencimiento: r.cuenta.fechaVencimiento,
          montoTotal: r.cuenta.monto,
          montoAbonado: 0.0,
          estado: r.cuenta.estado,
        ),
      )
      .toList();
});

final cuentaPagarPorIdProvider =
    FutureProvider.autoDispose.family<CuentaPagar?, int>(
  (Ref ref, int id) async {
    final dao = ref.watch(cuentasPagarDaoProvider);
    final cuenta = await dao.obtenerCuentaPorId(id);

    if (cuenta == null) return null;

    final pagos = await dao.listarPagosPorCuenta(id);
    final totalAbonado =
        pagos.fold<double>(0.0, (sum, p) => sum + p.monto);

    return CuentaPagar(
      id: cuenta.id,
      compraId: 0,
      nombreProveedor: '',
      numeroDocumento: cuenta.concepto,
      fechaEmision: cuenta.fechaEmision,
      fechaVencimiento: cuenta.fechaVencimiento,
      montoTotal: cuenta.monto,
      montoAbonado: totalAbonado,
      estado: cuenta.estado,
    );
  },
);

final historialAbonosProvider =
    FutureProvider.autoDispose.family<List<Abono>, int>(
  (Ref ref, int cuentaId) async {
    final dao = ref.watch(cuentasPagarDaoProvider);
    final registros = await dao.listarPagosPorCuenta(cuentaId);

    return registros
        .map(
          (r) => Abono(
            id: r.id,
            cuentaPagarId: r.cuentaPagarId,
            fecha: r.fechaPago,
            monto: r.monto,
            formaPago: r.formaPago,
            referencia: r.referencia ?? '',
            nota: r.nota,
          ),
        )
        .toList();
  },
);

final registrarAbonoProvider =
    Provider.autoDispose<
        Future<bool> Function({
          required int cuentaPagarId,
          required double monto,
          required DateTime fechaPago,
          String formaPago,
          String? referencia,
          String? nota,
        })>((Ref ref) {
  final dao = ref.read(cuentasPagarDaoProvider);

  return ({
    required int cuentaPagarId,
    required double monto,
    required DateTime fechaPago,
    String formaPago = 'efectivo',
    String? referencia,
    String? nota,
  }) async {
    try {
      final cuenta = await dao.obtenerCuentaPorId(cuentaPagarId);

      if (cuenta == null) {
        return false;
      }

      await dao.registrarAbono(
        cuentaPagarId: cuentaPagarId,
        proveedorId: cuenta.proveedorId,
        monto: monto,
        fechaPago: fechaPago,
        formaPago: formaPago,
        referencia: referencia,
        nota: nota,
      );

      ref.invalidate(listadoCuentasPagarProvider);
      ref.invalidate(cuentaPagarPorIdProvider(cuentaPagarId));
      ref.invalidate(historialAbonosProvider(cuentaPagarId));

      return true;
    } catch (e) {
      return false;
    }
  };
});
