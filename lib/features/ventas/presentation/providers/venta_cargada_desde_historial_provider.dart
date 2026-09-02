import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

class VentaCargadaNotifier extends StateNotifier<Venta?> {
  VentaCargadaNotifier() : super(null);
  void establecerVenta(Venta? venta) {
    state = venta;
  }

  void limpiarVenta() {
    state = null;
  }
}

final ventaCargadaDesdeHistorialProvider =
    StateNotifierProvider<VentaCargadaNotifier, Venta?>((ref) {
      return VentaCargadaNotifier();
    });
