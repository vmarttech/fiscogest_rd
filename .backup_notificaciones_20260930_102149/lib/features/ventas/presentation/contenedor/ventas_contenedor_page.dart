import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/auth/permisos_roles.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_hub_hero.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
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
    final sesion = ref.watch(sesionProvider);
    if (sesion != null && normalizarRol(sesion.rol) == 'Cajero') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/ventas/cobro');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final vistaActual = ref.watch(
      ventasNavegacionProvider.select((e) => e.vistaActual),
    );
    final modoOperacion = ref.watch(
      ventasNavegacionProvider.select((e) => e.modoOperacion),
    );
    final mobile = AppBreakpoints.isMobile(context);

    final String tituloApp = switch (modoOperacion) {
      ModoOperacion.venta || ModoOperacion.cobrar => 'VENTAS',
      ModoOperacion.cotizacion => 'COTIZACIONES',
      ModoOperacion.apartado => 'VENTAS',
    };

    final String heroTitulo = switch (modoOperacion) {
      ModoOperacion.venta || ModoOperacion.cobrar => 'Punto de venta',
      ModoOperacion.cotizacion => 'Cotizaciones',
      ModoOperacion.apartado => 'Punto de venta',
    };

    final String heroSub = switch (modoOperacion) {
      ModoOperacion.venta ||
      ModoOperacion.cobrar =>
        'Productos, carrito, cotizaciones e historial.',
      ModoOperacion.cotizacion =>
        'Arme presupuestos y envíelos a cobro en caja.',
      ModoOperacion.apartado =>
        'Productos, carrito, cotizaciones e historial.',
    };

    final IconData heroIcon = switch (modoOperacion) {
      ModoOperacion.cotizacion => Icons.request_quote_rounded,
      _ => Icons.storefront_rounded,
    };

    final Widget vistaActiva = switch (vistaActual) {
      VistaActual.inicio => const VistaInicioVacia(),
      VistaActual.inventario => const VistaInventario(),
      VistaActual.detalle => const VistaDetalle(),
      VistaActual.historial => const HistorialVentas(),
    };

    // En historial / detalle no mostramos hero (más espacio de lista)
    // En móvil tampoco: el hero ocupa demasiado y ya está el título en el AppBar
    final showHero = vistaActual == VistaActual.inicio && !mobile;

    return AppScaffold(
      title: tituloApp,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.6, -0.85),
            radius: 1.15,
            colors: [
              AppColors.primary.withValues(alpha: 0.07),
              AppColors.background,
            ],
          ),
        ),
        child: Column(
        children: [
          Expanded(
            child: showHero
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: AppLayout.pantallaPadding.add(
                          EdgeInsets.only(
                            top: mobile ? 8 : 12,
                            bottom: 0,
                          ),
                        ),
                        child: AppHubHero(
                          title: heroTitulo,
                          subtitle: heroSub,
                          icon: heroIcon,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(child: vistaActiva),
                    ],
                  )
                : vistaActiva,
          ),
        ],
      ),
      ),
    );
  }
}

