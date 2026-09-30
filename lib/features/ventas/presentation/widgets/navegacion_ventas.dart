import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// Sistema de diseño
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
// Enums y providers
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

class NavegacionVentas extends ConsumerWidget {
  const NavegacionVentas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = AppBreakpoints.isMobile(context);
    final anchoDrawer = isMobile ? 200.0 : 220.0;

    return Container(
      width: anchoDrawer,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: const Border(
          right: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppSpacing.s : AppSpacing.m,
              vertical: isMobile ? AppSpacing.s : AppSpacing.m,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Menú Ventas',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: isMobile ? 15 : 18,
                ),
              ),
            ),
          ),
          _buildListTile(
            context,
            icon: Icons.add_shopping_cart,
            title: 'Registrar Venta',
            isMobile: isMobile,
            onTap: () {
              Navigator.pop(context);
              ref
                  .read(ventasNavegacionProvider.notifier)
                  .establecerModoOperacion(ModoOperacion.venta);
              ref
                  .read(ventasNavegacionProvider.notifier)
                  .cambiarVista(VistaActual.inicio);
            },
          ),
          _buildListTile(
            context,
            icon: Icons.description,
            title: 'Cotizaciones',
            isMobile: isMobile,
            onTap: () {
              Navigator.pop(context);
              context.push('/ventas/cotizaciones/nueva');
            },
          ),
          _buildListTile(
            context,
            icon: Icons.undo,
            title: 'Devoluciones',
            isMobile: isMobile,
            onTap: () {
              Navigator.pop(context);
              ref
                  .read(ventasNavegacionProvider.notifier)
                  .cambiarVista(VistaActual.inventario);
            },
          ),
          _buildListTile(
            context,
            icon: Icons.payment,
            title: 'Cobrar',
            isMobile: isMobile,
            onTap: () {
              Navigator.pop(context);
              ref
                  .read(ventasNavegacionProvider.notifier)
                  .cambiarVista(VistaActual.inventario);
            },
          ),
          _buildListTile(
            context,
            icon: Icons.money_off,
            title: 'Pagar',
            isMobile: isMobile,
            onTap: () {
              Navigator.pop(context);
              FiscoGestNotifications.show(
                SnackBar(
                  content: Text(
                    'Pagar — Próximamente',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
          _buildListTile(
            context,
            icon: Icons.discount,
            title: 'Descuentos',
            isMobile: isMobile,
            onTap: () {
              Navigator.pop(context);
              FiscoGestNotifications.show(
                SnackBar(
                  content: Text(
                    'Descuentos — Próximamente',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
          _buildListTile(
            context,
            icon: Icons.local_offer,
            title: 'Ofertas',
            isMobile: isMobile,
            onTap: () {
              Navigator.pop(context);
              FiscoGestNotifications.show(
                SnackBar(
                  content: Text(
                    'Ofertas — Próximamente',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isMobile,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.xs : AppSpacing.s,
        vertical: AppSpacing.xs,
      ),
      child: ListTile(
        leading: Icon(icon, size: isMobile ? 18 : 20, color: AppColors.primary),
        title: Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            fontSize: isMobile ? 13 : 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allM),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.s : AppSpacing.m,
          vertical: isMobile ? 2 : AppSpacing.xs,
        ),
        hoverColor: AppColors.primary.withValues(alpha: 0.08),
        minLeadingWidth: isMobile ? 28 : 32,
      ),
    );
  }
}
