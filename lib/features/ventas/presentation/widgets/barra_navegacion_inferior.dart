import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';

class BarraNavegacionInferior extends ConsumerWidget {
  const BarraNavegacionInferior({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vistaActual = ref.watch(
      ventasNavegacionProvider.select((e) => e.vistaActual),
    );

    void irInicio() {
      ref
          .read(ventasNavegacionProvider.notifier)
          .establecerModoOperacion(ModoOperacion.cotizacion);
      ref
          .read(ventasNavegacionProvider.notifier)
          .cambiarVista(VistaActual.inicio);
    }

    void irHistorial() {
      ref
          .read(ventasNavegacionProvider.notifier)
          .cambiarVista(VistaActual.historial);
    }

    Widget boton({
      required bool activo,
      required IconData icono,
      required String etiqueta,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: activo ? AppColors.primary : Colors.transparent,
                  width: 2.5,
                ),
              ),
              color: activo
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
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

    final activoInicio = vistaActual == VistaActual.inicio;
    final activoHistorial = vistaActual == VistaActual.historial;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            boton(
              activo: activoInicio,
              icono: Icons.point_of_sale,
              etiqueta: 'Inicio',
              onTap: irInicio,
            ),
            boton(
              activo: activoHistorial,
              icono: Icons.history,
              etiqueta: 'Historial',
              onTap: irHistorial,
            ),
          ],
        ),
      ),
    );
  }
}
