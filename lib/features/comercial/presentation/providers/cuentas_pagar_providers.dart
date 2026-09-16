import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_pagar_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/cuentas_pagar/registrar_abono_usecase.dart';

final cuentasPagarDaoProvider = Provider<CuentasPagarDao>((ref) {
  final db = ref.watch(databaseProvider);
  return CuentasPagarDao(db);
});

final registrarAbonoUseCaseProvider = Provider<RegistrarAbonoUseCase>((ref) {
  final dao = ref.watch(cuentasPagarDaoProvider);
  return RegistrarAbonoUseCase(cuentasPagarDao: dao);
});

final historialPagosPorCuentaProvider = FutureProvider.family<List<PagoProveedorData>, int>((ref, cuentaId) async {
  final dao = ref.watch(cuentasPagarDaoProvider);
  return dao.listarPagosPorCuenta(cuentaId);
});

class CuentaPagarItem {
  const CuentaPagarItem({
    required this.id,
    required this.proveedorNombre,
    required this.concepto,
    required this.monto,
    required this.fechaEmision,
    required this.fechaVencimiento,
    required this.estado,
    required this.tipoGasto,
  });
  final int id;
  final String proveedorNombre;
  final String concepto;
  final double monto;
  final DateTime fechaEmision;
  final DateTime fechaVencimiento;
  final String estado;
  final String tipoGasto;
}

final listadoCuentasPagarProvider = FutureProvider<List<CuentaPagarItem>>((ref) async {
  final dao = ref.watch(cuentasPagarDaoProvider);
  final registros = await dao.listarCuentasPorPagar();
  return registros.map((reg) {
    final cuenta = reg.cuenta;
    final estadoTexto = switch (cuenta.estado) {
      PagarEstado.pagado => 'Pagada',
      PagarEstado.parcial => 'Abono parcial',
      PagarEstado.pendiente => 'Pendiente',
      PagarEstado.vencido => 'Vencida',
    };
    final tipoGastoTexto = switch (cuenta.tipoGasto) {
      TipoGasto.compra => 'Compra',
      TipoGasto.servicio => 'Servicio',
      TipoGasto.impuesto => 'Impuesto',
      TipoGasto.nomina => 'Nómina',
      TipoGasto.otro => 'Otro',
    };
    return CuentaPagarItem(
      id: cuenta.id,
      proveedorNombre: reg.nombreProveedor,
      concepto: cuenta.concepto,
      monto: cuenta.monto,
      fechaEmision: cuenta.fechaEmision,
      fechaVencimiento: cuenta.fechaVencimiento,
      estado: estadoTexto,
      tipoGasto: tipoGastoTexto,
    );
  }).toList();
});
