import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';

/// Vista inicial: estado vacío, guía al usuario
/// Cumple Diseño Nuevo: pantalla limpia, mensaje centrado, sin elementos innecesarios
class VistaInicioVacia extends ConsumerWidget {
  const VistaInicioVacia({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modo = ref.watch(
      ventasNavegacionProvider.select((estado) => estado.modoOperacion),
    );

    final String tituloModo = switch (modo) {
      ModoOperacion.venta => 'Nueva Venta',
      ModoOperacion.cotizacion => 'Nueva Venta Borrador',
      ModoOperacion.apartado => 'Nuevo Apartado',
    };

    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.allXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              tituloModo,
              style: AppTypography.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Seleccione una categoría desde la barra inferior para comenzar',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              alignment: WrapAlignment.center,
              children: [
                _TarjetaGuia(
                  icono: Icons.inventory_2_outlined,
                  texto: 'Productos',
                  color: AppColors.primary,
                  onTap: () => _irAInventario(ref, CategoriaProducto.productos),
                ),
                _TarjetaGuia(
                  icono: Icons.handyman_outlined,
                  texto: 'Manufactura',
                  color: AppColors.warning,
                  onTap: () => _irAInventario(ref, CategoriaProducto.manufactura),
                ),
                _TarjetaGuia(
                  icono: Icons.miscellaneous_services_outlined,
                  texto: 'Servicios',
                  color: AppColors.info,
                  onTap: () => _irAInventario(ref, CategoriaProducto.servicios),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _irAInventario(WidgetRef ref, CategoriaProducto categoria) {
    ref.read(ventasNavegacionProvider.notifier).cambiarCategoria(categoria);
    ref.read(ventasNavegacionProvider.notifier).cambiarVista(VistaActual.inventario);
  }
}

class _TarjetaGuia extends StatelessWidget {
  const _TarjetaGuia({
    required this.icono,
    required this.texto,
    required this.color,
    required this.onTap,
  });

  final IconData icono;
  final String texto;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: AppSpacing.allM,
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.05),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: color, size: 32),
            const SizedBox(height: AppSpacing.xs),
            Text(
              texto,
              style: AppTypography.labelMedium.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
