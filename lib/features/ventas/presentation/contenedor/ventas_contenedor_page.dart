import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
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
      ventasNavegacionProvider.select((e) => e.vistaActual),
    );
    final modoOperacion = ref.watch(
      ventasNavegacionProvider.select((e) => e.modoOperacion),
    );
    final String tituloDinamico = switch (modoOperacion) {
      ModoOperacion.venta => 'Gestión de Ventas',
      ModoOperacion.cotizacion => 'Gestión de Cotizaciones',
      ModoOperacion.apartado => 'Gestión de Apartados',
      ModoOperacion.cobrar => 'Cuentas por Cobrar',
    };
    final String subtitulo = switch (modoOperacion) {
      ModoOperacion.venta => 'Facturación y operaciones de venta',
      ModoOperacion.cotizacion => 'Cotizaciones y presupuestos',
      ModoOperacion.apartado => 'Apartados y reservas',
      ModoOperacion.cobrar => 'Gestión de cuentas por cobrar',
    };
    final Widget vistaActiva = switch (vistaActual) {
      VistaActual.inicio => const VistaInicioVacia(),
      VistaActual.inventario => const VistaInventario(),
      VistaActual.detalle => const VistaDetalle(),
      VistaActual.historial => const HistorialVentas(),
    };
    final isMobile = AppBreakpoints.isMobile(context);
    return AppScaffold(
      title: tituloDinamico,
      subtitle: isMobile ? null : subtitulo,
      actions: [
        IconButton(
          icon: const Icon(Icons.restore_from_trash_outlined),
          tooltip: 'Limpiar operación actual',
          onPressed: () {
            // TODO: conectar con la lógica de limpiar operación
          },
        ),
      ],
      body: Column(
        children: [
          if (!isMobile)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              color: AppColors.primary.withValues(alpha: 0.04),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _modoLabel(modoOperacion),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: vistaActiva),
          const BarraNavegacionInferior(),
        ],
      ),
    );
  }
  String _modoLabel(ModoOperacion modo) {
    return switch (modo) {
      ModoOperacion.venta => 'Modo Venta',
      ModoOperacion.cotizacion => 'Modo Cotización',
      ModoOperacion.apartado => 'Modo Apartado',
      ModoOperacion.cobrar => 'Modo Cobrar',
    };
  }
}
