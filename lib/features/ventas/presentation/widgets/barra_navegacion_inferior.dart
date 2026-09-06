import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/cobrar_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';

class BarraNavegacionInferior extends ConsumerWidget {
  const BarraNavegacionInferior({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vistaActual = ref.watch(ventasNavegacionProvider.select((e) => e.vistaActual));

    void navegarA(VistaActual destino) {
      ref.read(ventasNavegacionProvider.notifier).cambiarVista(destino);
    }

    Future<void> mostrarMenuMas() async {
      await showMenu<String>(
        context: context,
        position: const RelativeRect.fromLTRB(100, 0, 0, 100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        items: [
          PopupMenuItem<String>(
            child: ListTile(
              leading: const Icon(Icons.payments_outlined, color: AppColors.warning),
              title: const Text('Cuentas por Cobrar'),
              onTap: () {
                Navigator.pop(context);
                unawaited(context.pushNamed(CobrarPage.routeName));
              },
            ),
          ),
        ],
      );
    }

    Widget botonNavegacion(VistaActual vista, IconData icono, String etiqueta) {
      final activo = vistaActual == vista;
      return Expanded(
        child: InkWell(
          onTap: () => navegarA(vista),
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

    Widget botonMas() {
      return Expanded(
        child: InkWell(
          onTap: () => mostrarMenuMas(),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 22),
                SizedBox(height: 4),
                Text(
                  'Más',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.normal,
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
            botonNavegacion(VistaActual.inventario, Icons.inventory_2, 'Productos'),
            botonNavegacion(VistaActual.historial, Icons.history, 'Historial'),
            botonMas(),
          ],
        ),
      ),
    );
  }
}
