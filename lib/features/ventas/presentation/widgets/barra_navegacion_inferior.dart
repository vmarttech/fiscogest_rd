import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/selector_delivery.dart';

class BarraNavegacionInferior extends ConsumerWidget {
  const BarraNavegacionInferior({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vistaActual = ref.watch(ventasNavegacionProvider.select((e) => e.vistaActual));

    void navegarA(VistaActual destino) {
      ref.read(ventasNavegacionProvider.notifier).cambiarVista(destino);
    }

    Future<void> abrirSelectorDelivery() async {
      final costoActual = ref.read(registrarVentaProvider).costoEnvio;
      await showDialog<void>(
        context: context,
        builder: (ctx) => SelectorDeliveryDialog(costoActual: costoActual),
      );
    }

    Widget botonNavegacion(VistaActual vista, IconData icono, String etiqueta, {VoidCallback? onTapPersonalizado}) {
      final activo = vistaActual == vista;
      return Expanded(
        child: InkWell(
          onTap: onTapPersonalizado ?? () => navegarA(vista),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: activo ? AppColors.primary : Colors.transparent,
                  width: 2.5,
                ),
              ),
              color: activo ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icono,
                  color: activo ? AppColors.primary : AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(
                  etiqueta,
                  style: TextStyle(
                    fontSize: 11,
                    color: activo ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            botonNavegacion(VistaActual.inicio, Icons.point_of_sale, 'Inicio'),
            botonNavegacion(VistaActual.inventario, Icons.delivery_dining, 'Delivery', onTapPersonalizado: abrirSelectorDelivery),
            botonNavegacion(VistaActual.historial, Icons.history, 'Historial'),
          ],
        ),
      ),
    );
  }
}
