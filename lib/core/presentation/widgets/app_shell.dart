import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const navBgColor = Color(0xFF0F172A);
    const navSelectedColor = Color(0xFF1E293B);
    const navTextColor = Color(0xFF94A3B8);
    const navActiveTextColor = Colors.white;

    final currentPath = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 260,
            color: navBgColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24.0),
                  child: const Row(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.blueAccent, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('FiscoGest RD', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Versión 3.0 Pro', style: TextStyle(color: navTextColor, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF1E293B), height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    children: [
                      _buildNavItem(context, '/', 'Dashboard', Icons.dashboard_outlined, currentPath, navSelectedColor, navTextColor, navActiveTextColor),
                      _buildNavItem(context, '/sales', 'Facturación y NC', Icons.point_of_sale_outlined, currentPath, navSelectedColor, navTextColor, navActiveTextColor),
                      _buildNavItem(context, '/inventory', 'Inventario', Icons.inventory_2_outlined, currentPath, navSelectedColor, navTextColor, navActiveTextColor),
                      _buildNavItem(context, '/kardex', 'Kardex', Icons.receipt_long_outlined, currentPath, navSelectedColor, navTextColor, navActiveTextColor),
                      _buildNavItem(context, '/inventario-fisico', 'Inventario Físico', Icons.inventory_2, currentPath, navSelectedColor, navTextColor, navActiveTextColor),
                      _buildNavItem(context, '/customers', 'Clientes (DGII)', Icons.people_outline, currentPath, navSelectedColor, navTextColor, navActiveTextColor),
                      _buildNavItem(context, '/suppliers', 'Proveedores', Icons.business_outlined, currentPath, navSelectedColor, navTextColor, navActiveTextColor),
                      _buildNavItem(context, '/reports', 'Reportes 606/607', Icons.assessment_outlined, currentPath, navSelectedColor, navTextColor, navActiveTextColor),
                      _buildNavItem(context, '/taxes', 'Impuestos (ITBIS/ISR)', Icons.calculate_outlined, currentPath, navSelectedColor, navTextColor, navActiveTextColor),
                      _buildNavItem(context, '/import-export', 'Importar / Exportar', Icons.import_export, currentPath, navSelectedColor, navTextColor, navActiveTextColor),
                      _buildNavItem(context, '/settings', 'Configuración', Icons.settings_outlined, currentPath, navSelectedColor, navTextColor, navActiveTextColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(color: const Color(0xFFF4F6F9), child: child),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String routePath, String title, IconData icon, String currentPath, Color selectedBg, Color textColor, Color activeTextColor) {
    final isSelected = currentPath == routePath;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected ? selectedBg : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          leading: Icon(icon, color: isSelected ? activeTextColor : textColor, size: 20),
          title: Text(title, style: TextStyle(color: isSelected ? activeTextColor : textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
          onTap: () => context.go(routePath),
        ),
      ),
    );
  }
}