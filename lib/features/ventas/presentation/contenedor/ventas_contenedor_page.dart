import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
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

    // ✅ TODAS LAS VISTAS ORIGINALES MANTENIDAS SIN CAMBIOS
    // APARTADO comparte formulario, carrito y vistas con VENTA
    final Widget vistaActiva = switch (vistaActual) {
      VistaActual.inicio => const VistaInicioVacia(),
      VistaActual.inventario => const VistaInventario(),
      VistaActual.detalle => const VistaDetalle(),
      VistaActual.historial => const HistorialVentas(),
    };

    return AppScaffold(
      appBar: AppBar(
        title: Text(
          tituloDinamico,
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        elevation: 0.5,
        shadowColor: AppColors.border,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        titleSpacing: AppSpacing.m,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore_from_trash_outlined),
            tooltip: 'Limpiar operación actual',
            color: AppColors.textSecondary,
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(AppSpacing.s),
              minimumSize: const Size(40, 40),
            ),
            onPressed: () {},
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
