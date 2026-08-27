import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';

class VistaInicioVacia extends ConsumerWidget {
  const VistaInicioVacia({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modo = ref.watch(ventasNavegacionProvider.select((e) => e.modoOperacion));

    final titulo = switch (modo) {
      ModoOperacion.venta => 'Nueva Venta',
      ModoOperacion.cotizacion => 'Nueva Cotización',
      ModoOperacion.apartado => 'Nuevo Apartado',
      ModoOperacion.cobrar => 'Cuentas por Cobrar',
    };

    final subtitulo = switch (modo) {
      ModoOperacion.venta => 'Seleccione productos o servicios para iniciar una operación de venta',
      ModoOperacion.cotizacion => 'Seleccione productos o servicios para elaborar una cotización',
      ModoOperacion.apartado => 'Seleccione productos para registrar un apartado de cliente',
      ModoOperacion.cobrar => 'Consulte, administre y registre pagos de cuentas por cobrar',
    };

    final icono = switch (modo) {
      ModoOperacion.venta => Icons.point_of_sale_outlined,
      ModoOperacion.cotizacion => Icons.description_outlined,
      ModoOperacion.apartado => Icons.inventory_2_outlined,
      ModoOperacion.cobrar => Icons.payments_outlined,
    };

    final colorPrimario = switch (modo) {
      ModoOperacion.venta => AppColors.primary,
      ModoOperacion.cotizacion => AppColors.info,
      ModoOperacion.apartado => AppColors.success,
      ModoOperacion.cobrar => AppColors.warning,
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: colorPrimario.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                icono,
                size: 64,
                color: colorPrimario.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              titulo,
              style: AppTypography.h2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              subtitulo,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tips_and_updates_outlined, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: AppSpacing.s),
                  Text(
                    'Seleccione una categoría para comenzar',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
