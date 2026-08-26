import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Enums
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
// Providers
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_cargada_desde_historial_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';
// Vistas REALES
import 'package:fiscogest_rd/features/ventas/presentation/vistas/vista_inicio_vacia.dart';
import 'package:fiscogest_rd/features/ventas/presentation/vistas/vista_inventario.dart';
import 'package:fiscogest_rd/features/ventas/presentation/vistas/vista_detalle.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/widgets/historial_ventas.dart';

class ContenidoOperacionVenta extends ConsumerStatefulWidget {
  const ContenidoOperacionVenta({super.key});
  @override
  ConsumerState<ContenidoOperacionVenta> createState() => _ContenidoOperacionVentaState();
}

class _ContenidoOperacionVentaState extends ConsumerState<ContenidoOperacionVenta> {
  @override
  Widget build(BuildContext context) {
    final estadoNavegacion = ref.watch(ventasNavegacionProvider);

    // Solo mostrar detalle con datos cuando vista sea detalle Y haya venta cargada
    if (estadoNavegacion.vistaActual == VistaActual.detalle) {
      final ventaCargada = ref.watch(ventaCargadaDesdeHistorialProvider);
      if (ventaCargada != null) {
        return const VistaDetalle();
      }
    }

    // Limpiar venta cargada al cambiar de vista
    ref.read(ventaCargadaDesdeHistorialProvider.notifier).limpiarVenta();

    // Usar SIEMPRE las vistas REALES importadas
    switch (estadoNavegacion.vistaActual) {
      case VistaActual.inicio:
        return const VistaInicioVacia();
      case VistaActual.inventario:
        return const VistaInventario();
      case VistaActual.detalle:
        return const VistaDetalle();
      case VistaActual.historial:
        return const HistorialVentas();
    }
  }
}
