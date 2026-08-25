import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    const navWidth = 260.0;
    final currentPath = GoRouterState.of(context).uri.path;

    if (isMobile) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          title: const Text('FiscoGest RD', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        drawer: _buildMenu(navWidth, currentPath, context),
        body: child,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Row(
        children: [
          SizedBox(
            width: navWidth,
            child: _buildMenu(navWidth, currentPath, context),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildMenu(double width, String currentPath, BuildContext context) {
    return Container(
      width: width,
      color: const Color(0xFF0F172A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppSpacing.allL,
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.blueAccent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FiscoGest RD', style: AppTypography.h3.copyWith(color: Colors.white)),
                      Text('Versión 3.0 Pro', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),
          Expanded(
            child: ListView(
              padding: AppSpacing.vM.copyWith(left: AppSpacing.xs, right: AppSpacing.xs),
              children: [
                _buildNavItem(context, '/', 'Dashboard', Icons.dashboard_outlined, currentPath),
                _buildNavItem(context, '/sales', 'Facturación y NC', Icons.point_of_sale_outlined, currentPath),
                _buildNavItem(context, '/ventas', 'Ventas', Icons.point_of_sale, currentPath),
                _buildNavItem(context, '/compras', 'Compras', Icons.shopping_cart_outlined, currentPath),
                _buildNavItem(context, '/inventory', 'Inventario', Icons.inventory_2_outlined, currentPath),
                _buildNavItem(context, '/kardex', 'Kardex', Icons.receipt_long_outlined, currentPath),
                _buildNavItem(context, '/inventario-fisico', 'Inventario Físico', Icons.inventory_2, currentPath),
                _buildNavItem(context, '/customers', 'Clientes (DGII)', Icons.people_outline, currentPath),
                _buildNavItem(context, '/suppliers', 'Proveedores', Icons.business_outlined, currentPath),
                _buildNavItem(context, '/reports', 'Reportes 606/607', Icons.assessment_outlined, currentPath),
                _buildNavItem(context, '/taxes', 'Impuestos (ITBIS/ISR)', Icons.calculate_outlined, currentPath),
                _buildNavItem(context, '/import-export', 'Importar / Exportar', Icons.import_export, currentPath),
                _buildNavItem(context, '/settings', 'Configuración', Icons.settings_outlined, currentPath),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String routePath, String title, IconData icon, String currentPath) {
    final isSelected = currentPath == routePath;
    return Padding(
      padding: AppSpacing.vXs,
      child: Material(
        color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
        borderRadius: AppRadius.allM,
        child: InkWell(
          borderRadius: AppRadius.allM,
          onTap: () => context.go(routePath),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? Colors.white : AppColors.textSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
