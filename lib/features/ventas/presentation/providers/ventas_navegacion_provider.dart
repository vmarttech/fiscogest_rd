import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';

/// Provider dedicado exclusivamente al control de navegación interna UI
/// NO toca lógica de negocio, cálculos ni persistencia
/// Cumple Plan de Centralización UI: separación estricta de responsabilidades
final ventasNavegacionProvider =
    StateNotifierProvider<VentasNavegacionNotifier, VentasNavegacionState>(
      (ref) => VentasNavegacionNotifier(),
    );

class VentasNavegacionState {
  const VentasNavegacionState({
    this.vistaActual = VistaActual.inicio,
    this.modoOperacion = ModoOperacion.venta,
    this.categoriaSeleccionada = CategoriaProducto.productos,
  });
  final VistaActual vistaActual;
  final ModoOperacion modoOperacion;
  final CategoriaProducto categoriaSeleccionada;
  VentasNavegacionState copiarCon({
    VistaActual? vistaActual,
    ModoOperacion? modoOperacion,
    CategoriaProducto? categoriaSeleccionada,
  }) {
    return VentasNavegacionState(
      vistaActual: vistaActual ?? this.vistaActual,
      modoOperacion: modoOperacion ?? this.modoOperacion,
      categoriaSeleccionada:
          categoriaSeleccionada ?? this.categoriaSeleccionada,
    );
  }
}

class VentasNavegacionNotifier extends StateNotifier<VentasNavegacionState> {
  VentasNavegacionNotifier() : super(const VentasNavegacionState());
  void cambiarVista(VistaActual nuevaVista) {
    state = state.copiarCon(vistaActual: nuevaVista);
  }

  void establecerModoOperacion(ModoOperacion modo) {
    state = state.copiarCon(
      modoOperacion: modo,
      vistaActual: VistaActual.inicio,
    );
  }

  void cambiarCategoria(CategoriaProducto categoria) {
    state = state.copiarCon(categoriaSeleccionada: categoria);
  }

  void volverAlInicio() {
    state = state.copiarCon(vistaActual: VistaActual.inicio);
  }
}
