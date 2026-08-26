import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/barra_navegacion_inferior.dart';
import 'package:fiscogest_rd/features/ventas/presentation/vistas/vista_inicio_vacia.dart';
import 'package:fiscogest_rd/features/ventas/presentation/vistas/vista_inventario.dart';
import 'package:fiscogest_rd/features/ventas/presentation/vistas/vista_detalle.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/widgets/historial_ventas.dart';
class VentasContenedorPage extends ConsumerStatefulWidget {
  const VentasContenedorPage({
    super.key,
    this.modoInicial = ModoOperacion.venta,
  });
  static const String nombreRuta = 'ventas-contenedor';
  final ModoOperacion modoInicial;
  @override
  ConsumerState<VentasContenedorPage> createState() =>
      _VentasContenedorPageState();
}
class _VentasContenedorPageState extends ConsumerState<VentasContenedorPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(ventasNavegacionProvider.notifier)
          .establecerModoOperacion(widget.modoInicial);
    });
  }
  @override
  Widget build(BuildContext context) {
    final vistaActual = ref.watch(
      ventasNavegacionProvider.select((estado) => estado.vistaActual),
    );
    final modoOperacion = ref.watch(
      ventasNavegacionProvider.select((estado) => estado.modoOperacion),
    );
    final String tituloAppBar = switch (modoOperacion) {
      ModoOperacion.venta => 'Ventas',
      ModoOperacion.cotizacion => 'Cotizaciones',
      ModoOperacion.apartado => 'Apartados',
    };
    Widget vistaActiva;
    switch (vistaActual) {
      case VistaActual.inicio:
        vistaActiva = const VistaInicioVacia();
        break;
      case VistaActual.inventario:
        vistaActiva = const VistaInventario();
        break;
      case VistaActual.detalle:
        final ventaCargada = ref.watch(ventaCargadaDesdeHistorialProvider);
        vistaActiva = ventaCargada != null
            ? const VistaDetalle()
            : const VistaDetalle();
        break;
      case VistaActual.historial:
        vistaActiva = const HistorialVentas();
        break;
    }
    return AppScaffold(
      appBar: AppBar(
        title: Text(tituloAppBar),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            color: vistaActual == VistaActual.historial
                ? AppColors.primary
                : AppColors.textSecondary,
            onPressed: () {
              ref.read(ventasNavegacionProvider.notifier).cambiarVista(VistaActual.historial);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Limpiar operación',
            color: AppColors.textSecondary,
            onPressed: () {
              ref.read(registrarVentaProvider.notifier).vaciarVenta();
              ref.read(ventaCargadaDesdeHistorialProvider.notifier).limpiarVenta();
              ref.read(ventasNavegacionProvider.notifier).volverAlInicio();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: vistaActiva),
          const BarraNavegacionInferior(),
        ],
      ),
    );
  }
}
