import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/cobrar_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';

class BarraNavegacionInferior extends ConsumerWidget {
  const BarraNavegacionInferior({super.key});
  static const double alturaBarra = 72.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final VistaActual vistaActiva = ref.watch(
      ventasNavegacionProvider.select((e) => e.vistaActual),
    );
    final ModoOperacion modoActivo = ref.watch(
      ventasNavegacionProvider.select((e) => e.modoOperacion),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BotonPrincipal(
                icono: Icons.point_of_sale,
                etiqueta: 'Venta',
                activo: vistaActiva == VistaActual.inicio &&
                    modoActivo == ModoOperacion.venta,
                color: AppColors.primary,
                onTap: () {
                  ref
                      .read(ventasNavegacionProvider.notifier)
                      .establecerModoOperacion(ModoOperacion.venta);
                  ref
                      .read(ventasNavegacionProvider.notifier)
                      .cambiarVista(VistaActual.inicio);
                },
              ),
              _BotonPrincipal(
                icono: Icons.inventory_2_outlined,
                etiqueta: 'Productos',
                activo: vistaActiva == VistaActual.inventario,
                color: AppColors.primary,
                onTap: () {
                  ref
                      .read(ventasNavegacionProvider.notifier)
                      .cambiarVista(VistaActual.inventario);
                },
              ),
              _BotonPrincipal(
                icono: Icons.description_outlined,
                etiqueta: 'Cotizar',
                activo: modoActivo == ModoOperacion.cotizacion,
                color: AppColors.info,
                onTap: () {
                  ref
                      .read(ventasNavegacionProvider.notifier)
                      .establecerModoOperacion(ModoOperacion.cotizacion);
                  ref
                      .read(ventasNavegacionProvider.notifier)
                      .cambiarVista(VistaActual.inicio);
                },
              ),
              _BotonPrincipal(
                icono: Icons.more_horiz,
                etiqueta: 'Más',
                activo: false,
                color: AppColors.textSecondary,
                onTap: () => _mostrarMenuSecundario(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarMenuSecundario(
      BuildContext context, WidgetRef ref) async {
    await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 0, 0, 100),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem<String>(
          child: ListTile(
            leading: const Icon(Icons.lock_outlined, color: AppColors.success),
            title: const Text('Apartado'),
            onTap: () {
              Navigator.pop(context);
              ref
                  .read(ventasNavegacionProvider.notifier)
                  .establecerModoOperacion(ModoOperacion.apartado);
              ref
                  .read(ventasNavegacionProvider.notifier)
                  .cambiarVista(VistaActual.inicio);
            },
          ),
        ),
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
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          child: ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historial'),
            onTap: () {
              Navigator.pop(context);
              ref
                  .read(ventasNavegacionProvider.notifier)
                  .cambiarVista(VistaActual.historial);
            },
          ),
        ),
      ],
    );
  }
}

class _BotonPrincipal extends StatelessWidget {
  const _BotonPrincipal({
    required this.icono,
    required this.etiqueta,
    required this.activo,
    required this.color,
    required this.onTap,
  });
  final IconData icono;
  final String etiqueta;
  final bool activo;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icono,
              color: activo ? color : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              etiqueta,
              style: TextStyle(
                color: activo ? color : AppColors.textSecondary,
                fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
