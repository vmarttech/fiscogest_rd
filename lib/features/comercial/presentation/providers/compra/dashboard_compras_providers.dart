import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart' as repo;

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
  try {
    final compraRepo = ref.watch(repo.compraRepositoryProvider);
    final cuentasDao = ref.watch(repo.cuentasPagarDaoProvider);

    final ahora = DateTime.now();
    final inicioMes = DateTime(ahora.year, ahora.month, 1);

    final compras = await compraRepo.listarCompras();
    debugPrint('[KPI] compras cargadas: ${compras.length}');

    final cuentasConProveedor = await cuentasDao.listarCuentasPorPagar();
    debugPrint('[KPI] cuentas por pagar: ${cuentasConProveedor.length}');

    final comprasMes = compras.where((Compra c) {
      final fecha = c.fechaEmision;
      final mismoMes = fecha.year == ahora.year && fecha.month == ahora.month;
      final valida =
          c.estado != EstadoCompra.borrador && c.estado != EstadoCompra.anulada;
      return mismoMes && valida && !fecha.isBefore(inicioMes);
    }).toList();

    final double totalMes = comprasMes.fold<double>(
      0,
      (sum, c) => sum + c.totalCompra,
    );

    final double aCreditoMes = comprasMes
        .where((c) => c.esCredito)
        .fold<double>(0, (sum, c) => sum + c.totalCompra);

    double porPagar = 0;
    double vencido = 0;

    for (final item in cuentasConProveedor) {
      try {
        final cuenta = item.cuenta;
        final estado = cuenta.estado;

        if (estado == PagarEstado.pagado) continue;

        final pagos = await cuentasDao.listarPagosPorCuenta(cuenta.id);
        final totalAbonado =
            pagos.fold<double>(0, (s, p) => s + p.monto);
        final saldo = cuenta.monto - totalAbonado;

        if (saldo <= 0) continue;

        final fechaVenc = cuenta.fechaVencimiento;
        final bool estaVencida = estado == PagarEstado.vencido ||
            ahora.isAfter(fechaVenc);

        if (estaVencida) {
          vencido += saldo;
        } else {
          porPagar += saldo;
        }
      } catch (e, st) {
        debugPrint('[KPI] cuenta omitida: $e\n$st');
      }
    }

    return DashboardComprasKpis(
      comprasEsteMes: totalMes,
      aCreditoEsteMes: aCreditoMes,
      porPagar: porPagar,
      vencido: vencido,
    );
  } catch (e, st) {
    debugPrint('[KPI] ERROR FATAL: $e\n$st');
    rethrow;
  }
});

final actividadRecienteComprasProvider =
    FutureProvider.autoDispose<List<ActividadRecienteItem>>((ref) async {
  try {
    final compraRepo = ref.watch(repo.compraRepositoryProvider);
    final compras = await compraRepo.listarCompras();
    debugPrint('[Actividad] compras: ${compras.length}');

    final recientes = compras
        .where((c) =>
            c.estado != EstadoCompra.borrador &&
            c.estado != EstadoCompra.anulada)
        .toList()
      ..sort((a, b) => b.fechaEmision.compareTo(a.fechaEmision));

    return recientes.take(8).map((c) {
      return ActividadRecienteItem(
        compraId: c.id,
        fecha: c.fechaEmision,
        proveedorNombre:
            c.nombreProveedor.isEmpty ? 'Sin nombre' : c.nombreProveedor,
        total: c.totalCompra,
        estado: c.estado,
      );
    }).toList();
  } catch (e, st) {
    debugPrint('[Actividad] ERROR FATAL: $e\n$st');
    rethrow;
  }
});
