import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
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
      ModoOperacion.venta => 'Busque o seleccione productos para iniciar una venta',
      ModoOperacion.cotizacion => 'Busque o seleccione productos para crear una cotización',
      ModoOperacion.apartado => 'Busque o seleccione productos para registrar un apartado',
      ModoOperacion.cobrar => 'Consulte y administre sus cuentas por cobrar',
    };
    final icono = switch (modo) {
      ModoOperacion.venta => Icons.point_of_sale_outlined,
      ModoOperacion.cotizacion => Icons.description_outlined,
      ModoOperacion.apartado => Icons.inventory_2_outlined,
      ModoOperacion.cobrar => Icons.payments_outlined,
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 80, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text(titulo, style: AppTypography.h2),
            const SizedBox(height: 12),
            Text(subtitulo, style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
