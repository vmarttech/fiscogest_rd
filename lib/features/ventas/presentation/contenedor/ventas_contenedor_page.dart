import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/barra_navegacion_inferior.dart';
import 'package:fiscogest_rd/features/ventas/presentation/vistas/vista_inicio_vacia.dart';
import 'package:fiscogest_rd/features/ventas/presentation/vistas/vista_inventario.dart';

/// CONTENEDOR ÚNICO DEL MÓDULO VENTAS
/// ✅ Integra VistaInventario conectada a tu fuente real de productos
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

    return AppScaffold(
      appBar: AppBar(
        title: Text(tituloAppBar),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Limpiar operación',
            color: AppColors.textSecondary,
            onPressed: _limpiarOperacion,
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Confirmar',
            color: AppColors.primary,
            onPressed: _confirmarOperacion,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: vistaActual.index,
              children: [
                const VistaInicioVacia(),
                const VistaInventario(),
                _construirVistaDetalle(),
              ],
            ),
          ),
          const BarraNavegacionInferior(),
        ],
      ),
    );
  }

  Widget _construirVistaDetalle() {
    return const _VistaPlaceholder(
      icono: Icons.receipt_long_outlined,
      titulo: 'Detalle de operación',
      descripcion:
          'Aquí se integrará el formulario completo: cantidad, precio, descuento, cliente, pago',
    );
  }

  void _limpiarOperacion() {
    ref.read(ventasNavegacionProvider.notifier).volverAlInicio();
  }

  void _confirmarOperacion() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Confirmación conectará con caso de uso oficial'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _VistaPlaceholder extends StatelessWidget {
  const _VistaPlaceholder({
    required this.icono,
    required this.titulo,
    required this.descripcion,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.allXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              titulo,
              style: AppTypography.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              descripcion,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
