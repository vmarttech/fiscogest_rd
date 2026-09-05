import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_pagar_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

class CuentaPagarItem {
  const CuentaPagarItem({
    required this.proveedorNombre,
    required this.concepto,
    required this.monto,
    required this.fechaEmision,
    required this.fechaVencimiento,
    required this.estado,
    required this.tipoGasto,
  });

  final String proveedorNombre;
  final String concepto;
  final double monto;
  final DateTime fechaEmision;
  final DateTime fechaVencimiento;
  final String estado;
  final String tipoGasto;
}

final listadoCuentasPagarProvider = FutureProvider<List<CuentaPagarItem>>((
  ref,
) async {
  final db = ref.watch(databaseProvider);
  final dao = CuentasPagarDao(db);
  final registros = await dao.listarCuentasPorPagar();
  return registros.map((reg) {
    final cuenta = reg.cuenta;
    final estadoTexto = switch (cuenta.estado) {
      PagarEstado.pendiente => 'Pendiente',
      PagarEstado.vencido => 'Vencido',
      PagarEstado.pagado => 'Pagado',
      _ => 'Desconocido',
    };
    final tipoGastoTexto = switch (cuenta.tipoGasto) {
      TipoGasto.compra => 'Compra',
      TipoGasto.servicio => 'Servicio',
      TipoGasto.impuesto => 'Impuesto',
      TipoGasto.nomina => 'Nómina',
      TipoGasto.otro => 'Otro',
    };
    return CuentaPagarItem(
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
