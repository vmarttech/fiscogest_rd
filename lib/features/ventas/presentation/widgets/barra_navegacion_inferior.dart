import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';

/// Barra de navegación INFERIOR FIJA permanente
/// Cumple Diseño Nuevo: siempre visible, nunca se recarga, misma en todas las vistas
/// Cumple Plan Centralización UI: usa exclusivamente constantes core reales
class BarraNavegacionInferior extends ConsumerWidget {
  const BarraNavegacionInferior({super.key});

  static const double alturaBarra = 70.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriaActiva = ref.watch(
      ventasNavegacionProvider.select((estado) => estado.categoriaSeleccionada),
    );

    return Container(
      height: alturaBarra,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BotonCategoria(
              categoria: CategoriaProducto.productos,
              activa: categoriaActiva == CategoriaProducto.productos,
              icono: Icons.inventory_2_outlined,
              etiqueta: 'Productos',
              color: AppColors.primary,
            ),
            _BotonCategoria(
              categoria: CategoriaProducto.manufactura,
              activa: categoriaActiva == CategoriaProducto.manufactura,
              icono: Icons.handyman_outlined,
              etiqueta: 'Manufactura',
              color: AppColors.warning,
            ),
            _BotonCategoria(
              categoria: CategoriaProducto.servicios,
              activa: categoriaActiva == CategoriaProducto.servicios,
              icono: Icons.miscellaneous_services_outlined,
              etiqueta: 'Servicios',
              color: AppColors.info,
            ),
            _BotonCategoria(
              categoria: CategoriaProducto.scanner,
              activa: categoriaActiva == CategoriaProducto.scanner,
              icono: Icons.qr_code_scanner_outlined,
              etiqueta: 'Scanner',
              color: AppColors.success,
            ),
          ],
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
      borderRadius: BorderRadius.circular(AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icono,
              color: activa ? color : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              etiqueta,
              style: AppTypography.labelSmall.copyWith(
                color: activa ? color : AppColors.textSecondary,
                fontWeight: activa ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
