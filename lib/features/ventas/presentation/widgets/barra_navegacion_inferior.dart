import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/cobrar_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';

class BarraNavegacionInferior extends ConsumerWidget {
  const BarraNavegacionInferior({super.key});
  static const double alturaBarra = 72.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriaActiva = ref.watch(
      ventasNavegacionProvider.select((estado) => estado.categoriaSeleccionada),
    );
    final modoActivo = ref.watch(
      ventasNavegacionProvider.select((estado) => estado.modoOperacion),
    );

    return Container(
      height: alturaBarra,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: 4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _BotonCategoria(
                        categoria: CategoriaProducto.productos,
                        activa: categoriaActiva == CategoriaProducto.productos,
                        icono: Icons.inventory_2_outlined,
                        etiqueta: 'Productos',
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      _BotonCategoria(
                        categoria: CategoriaProducto.manufactura,
                        activa:
                            categoriaActiva == CategoriaProducto.manufactura,
                        icono: Icons.handyman_outlined,
                        etiqueta: 'Manufactura',
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      _BotonCategoria(
                        categoria: CategoriaProducto.servicios,
                        activa: categoriaActiva == CategoriaProducto.servicios,
                        icono: Icons.miscellaneous_services_outlined,
                        etiqueta: 'Servicios',
                        color: AppColors.info,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      _BotonCategoria(
                        categoria: CategoriaProducto.scanner,
                        activa: categoriaActiva == CategoriaProducto.scanner,
                        icono: Icons.qr_code_scanner_outlined,
                        etiqueta: 'Escanear',
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Container(width: 1, height: 40, color: AppColors.border),
              const SizedBox(width: AppSpacing.m),
              _BotonOperaciones(modoActivo: modoActivo),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonCategoria extends ConsumerWidget {
  const _BotonCategoria({
    required this.categoria,
    required this.activa,
    required this.icono,
    required this.etiqueta,
    required this.color,
  });

  final CategoriaProducto categoria;
  final bool activa;
  final IconData icono;
  final String etiqueta;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        ref.read(ventasNavegacionProvider.notifier).cambiarCategoria(categoria);
        ref
            .read(ventasNavegacionProvider.notifier)
            .cambiarVista(VistaActual.inventario);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s,
          vertical: 4,
        ),
        decoration: activa
            ? BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.35),
                  width: 1,
                ),
              )
            : BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icono,
              color: activa ? color : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              etiqueta,
              style: AppTypography.labelSmall.copyWith(
                color: activa ? color : AppColors.textSecondary,
                fontWeight: activa ? FontWeight.w600 : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonOperaciones extends ConsumerWidget {
  const _BotonOperaciones({required this.modoActivo});

  final ModoOperacion modoActivo;

  String _etiquetaModo() {
    return switch (modoActivo) {
      ModoOperacion.venta => 'Venta',
      ModoOperacion.cotizacion => 'Cotización',
      ModoOperacion.apartado => 'Apartado',
      ModoOperacion.cobrar => 'Por Cobrar',
    };
  }

  Color _colorModo() {
    return switch (modoActivo) {
      ModoOperacion.venta => AppColors.primary,
      ModoOperacion.cotizacion => AppColors.info,
      ModoOperacion.apartado => AppColors.success,
      ModoOperacion.cobrar => AppColors.warning,
    };
  }

  Future<void> _mostrarMenu(BuildContext context, WidgetRef ref) async {
    final seleccion = await showMenu<ModoOperacion>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 0, 0, 100),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          value: ModoOperacion.venta,
          child: Row(
            children: [
              const Icon(
                Icons.point_of_sale_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s),
              const Text('Venta'),
              if (modoActivo == ModoOperacion.venta) ...[
                const Spacer(),
                const Icon(Icons.check, color: AppColors.primary, size: 18),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: ModoOperacion.cotizacion,
          child: Row(
            children: [
              const Icon(
                Icons.description_outlined,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s),
              const Text('Cotización'),
              if (modoActivo == ModoOperacion.cotizacion) ...[
                const Spacer(),
                const Icon(Icons.check, color: AppColors.info, size: 18),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: ModoOperacion.apartado,
          child: Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s),
              const Text('Apartado'),
              if (modoActivo == ModoOperacion.apartado) ...[
                const Spacer(),
                const Icon(Icons.check, color: AppColors.success, size: 18),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: ModoOperacion.cobrar,
          child: Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s),
              const Text('Cuentas por Cobrar'),
              if (modoActivo == ModoOperacion.cobrar) ...[
                const Spacer(),
                const Icon(Icons.check, color: AppColors.warning, size: 18),
              ],
            ],
          ),
        ),
      ],
    );

    if (seleccion == ModoOperacion.cobrar) {
      if (context.mounted) unawaited(context.pushNamed(CobrarPage.routeName));
      return;
    }

    if (seleccion != null && seleccion != modoActivo) {
      ref
          .read(ventasNavegacionProvider.notifier)
          .establecerModoOperacion(seleccion);
      ref
          .read(ventasNavegacionProvider.notifier)
          .cambiarVista(VistaActual.inventario);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _colorModo();
    return InkWell(
      onTap: () => _mostrarMenu(context, ref),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.expand_circle_down_outlined, color: color, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Operaciones',
                  style: AppTypography.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              _etiquetaModo(),
              style: AppTypography.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
