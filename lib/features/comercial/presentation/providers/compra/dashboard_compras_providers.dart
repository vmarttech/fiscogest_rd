import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart' as repo;

/// Modelo simple para los KPIs del dashboard
class DashboardComprasKpis {
  const DashboardComprasKpis({
    required this.comprasEsteMes,
    required this.aCreditoEsteMes,
    required this.porPagar,
    required this.vencido,
  });

  final double comprasEsteMes;
  final double aCreditoEsteMes;
  final double porPagar;
  final double vencido;
}

/// Actividad reciente (últimas compras)
class ActividadRecienteItem {
  const ActividadRecienteItem({
    required this.compraId,
    required this.fecha,
    required this.proveedorNombre,
    required this.total,
    required this.estado,
  });

  final int compraId;
  final DateTime fecha;
  final String proveedorNombre;
  final double total;
  final EstadoCompra estado;
}

final dashboardComprasKpisProvider =
    FutureProvider.autoDispose<DashboardComprasKpis>((ref) async {
  final compraRepo = ref.watch(repo.compraRepositoryProvider);
  final cuentasDao = ref.watch(repo.cuentasPagarDaoProvider);

  final ahora = DateTime.now();
  final inicioMes = DateTime(ahora.year, ahora.month, 1);

  final compras = await compraRepo.listarCompras();
  final cuentasConProveedor = await cuentasDao.listarCuentasPorPagar();

  // Solo compras del mes actual que no estén en borrador ni anuladas
  final comprasMes = compras.where((Compra c) {
    final fecha = c.fechaEmision;
    final mismoMes = fecha.year == ahora.year && fecha.month == ahora.month;
    final valida = c.estado != EstadoCompra.borrador &&
        c.estado != EstadoCompra.anulada;
    return mismoMes && valida && !fecha.isBefore(inicioMes);
  }).toList();

  final double totalMes = comprasMes.fold<double>(
    0,
    (double sum, Compra c) => sum + c.totalCompra,
  );

  final double aCreditoMes = comprasMes
      .where((Compra c) => c.esCredito)
      .fold<double>(0, (double sum, Compra c) => sum + c.totalCompra);

  // Cuentas pendientes / parciales → por pagar
  // Cuentas vencidas (por estado o por fecha) → vencido
  double porPagar = 0;
  double vencido = 0;

  for (final item in cuentasConProveedor) {
    final cuenta = item.cuenta;
    final estado = cuenta.estado;

    if (estado == PagarEstado.pagado) continue;

    // Calcular saldo pendiente = monto - suma de abonos
    final pagos = await cuentasDao.listarPagosPorCuenta(cuenta.id);
    final totalAbonado =
        pagos.fold<double>(0, (double s, p) => s + (p.monto ));
    final saldo = (cuenta.monto ) - totalAbonado;
    if (saldo <= 0) continue;

    final DateTime fechaVenc = cuenta.fechaVencimiento;
    final bool estaVencida = estado == PagarEstado.vencido ||
        (DateTime.now().isAfter(fechaVenc));

    if (estaVencida) {
      vencido += saldo;
    } else {
      porPagar += saldo;
    }
  }

  return DashboardComprasKpis(
    comprasEsteMes: totalMes,
    aCreditoEsteMes: aCreditoMes,
    porPagar: porPagar,
    vencido: vencido,
  );
});

final actividadRecienteComprasProvider =
    FutureProvider.autoDispose<List<ActividadRecienteItem>>((ref) async {
  final compraRepo = ref.watch(repo.compraRepositoryProvider);
  final compras = await compraRepo.listarCompras();

  final recientes = compras
      .where((Compra c) =>
          c.estado != EstadoCompra.borrador &&
          c.estado != EstadoCompra.anulada)
      .toList()
    ..sort((a, b) => b.fechaEmision.compareTo(a.fechaEmision));

  return recientes.take(8).map((Compra c) {
    return ActividadRecienteItem(
      compraId: c.id,
      fecha: c.fechaEmision,
      proveedorNombre: c.nombreProveedor,
      total: c.totalCompra,
      estado: c.estado,
    );
  }).toList();
});
