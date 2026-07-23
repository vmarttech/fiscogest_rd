import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogestrd/models/operacion.dart';
import 'package:fiscogestrd/repositories/operacion_repository.dart';
import 'package:fiscogestrd/providers/producto_notifier.dart';

class OperacionNotifier extends StateNotifier<Map<String, List>> {
  // ✅ CONSTRUCTOR PRIMERO
  OperacionNotifier(this._repo, this._ref) : super({'compras': [], 'ventas': []});

  final OperacionRepository _repo;
  final Ref _ref;

  /// ✅ Registrar Compra + actualizar inventario automáticamente
  Future<void> registrarCompra(Compra compra) async {
    final id = await _repo.guardarCompra(compra);
    final compraGuardada = compra.copyWith(id: id);

    // Actualizar stock de productos
    for (final detalle in compra.detalles) {
      await _ref.read(productoNotifierProvider.notifier)
          .aumentarStock(detalle.productoId, detalle.cantidad);
    }

    // ✅ Evita error de valor nulo
    state = {
      ...state,
      'compras': [...?state['compras'], compraGuardada]
    };
  }

  /// ✅ Registrar Venta + validar stock + descontar inventario
  Future<bool> registrarVenta(Venta venta) async {
    bool puedeVender = true;
    for (final detalle in venta.detalles) {
      final ok = await _ref.read(productoNotifierProvider.notifier)
          .descontarStock(detalle.productoId, detalle.cantidad);
      if (!ok) {
        puedeVender = false;
        break;
      }
    }

    if (!puedeVender) return false;

    final id = await _repo.guardarVenta(venta);
    final ventaGuardada = venta.copyWith(id: id);

    // ✅ Evita error de valor nulo
    state = {
      ...state,
      'ventas': [...?state['ventas'], ventaGuardada]
    };

    return true;
  }

  Future<void> cargarTodo({DateTime? desde, DateTime? hasta}) async {
    final compras = await _repo.obtenerCompras(desde: desde, hasta: hasta);
    final ventas = await _repo.obtenerVentas(desde: desde, hasta: hasta);
    state = {'compras': compras, 'ventas': ventas};
  }

  /// ✅ Resumen fiscal automático para el periodo
  Map<String, double> obtenerResumenFiscal() {
    final compras = state['compras'] as List<Compra>;
    final ventas = state['ventas'] as List<Venta>;

    double itbisAcreditable = 0.0;
    double itbisGenerado = 0.0;
    double impSelectivoPagado = 0.0;
    double impSelectivoCobrado = 0.0;

    for (final c in compras) {
      itbisAcreditable += c.itbisAcreditable;
      impSelectivoPagado += c.impuestoSelectivo;
    }

    for (final v in ventas) {
      itbisGenerado += v.itbisGenerado;
      impSelectivoCobrado += v.impuestoSelectivo;
    }

    final saldo = itbisGenerado - itbisAcreditable;

    return {
      'itbisAcreditable': itbisAcreditable,
      'itbisGenerado': itbisGenerado,
      'saldoITBIS': saldo > 0 ? saldo : 0,
      'saldoAFavor': saldo < 0 ? saldo.abs() : 0,
      'impSelectivoNeto': impSelectivoCobrado - impSelectivoPagado,
    };
  }
}

// ✅ Proveedores
final operacionRepositoryProvider = Provider((ref) => OperacionRepository());

final operacionNotifierProvider =
    StateNotifierProvider<OperacionNotifier, Map<String, List>>((ref) {
  final repo = ref.watch(operacionRepositoryProvider);
  return OperacionNotifier(repo, ref);
});