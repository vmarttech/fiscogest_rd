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

  String _obtenerTituloPantalla(String rutaActual) {
    return switch (rutaActual) {
      '/' => 'Dashboard',
      '/sales' => 'Facturación y NC',
      '/ventas' => 'Ventas',
      '/ventas/cotizaciones/nueva' => 'Nueva Cotización',
      '/ventas/cotizaciones/historial' => 'Historial de Cotizaciones',
      '/ventas/apartados' => 'Apartados',
      '/ventas/devoluciones' => 'Devoluciones',
      '/ventas/descuentos' => 'Descuentos',
      '/ventas/ofertas' => 'Ofertas',
      '/ventas/cobrar' => 'Cuentas por Cobrar',
      '/ventas/pagar' => 'Cuentas por Pagar',
      '/compras' => 'Compras',
      '/compras/lista' => 'Lista de Compras',
      '/compras/registrar' => 'Registrar Compra',
      '/compras/detalle' => 'Detalle de Compra',
      '/compras/cuentas-pagar' => 'Cuentas por Pagar',
      '/compras/recepcion' => 'Recepción de Compra',
      '/inventario' => 'Inventario',
      '/kardex' => 'Kárdex',
      '/productos/nuevo' => 'Nuevo Producto',
      '/inventario/entrada' => 'Entrada de Producto',
      '/inventario/salida' => 'Salida de Producto',
      '/inventario-fisico' => 'Inventario Físico',
      '/inventario-fisico/listar' => 'Lista de Conteos',
      '/diferencias-conteo-fisico' => 'Diferencias de Conteo',
      '/lista-ajustes' => 'Lista de Ajustes',
      '/registrar-ajuste' => 'Registrar Ajuste',
      '/ajustes-inventario' => 'Ajustes de Inventario',
      '/ajustes-inventario/nuevo' => 'Nuevo Ajuste',
      '/clientes' => 'Clientes',
      '/clientes/gestion' => 'Gestión de Cliente',
      '/proveedores' => 'Proveedores',
      '/transferencias/registrar' => 'Registrar Transferencia',
      '/presentaciones' => 'Presentaciones',
      '/categorias' => 'Categorías',
      '/marcas' => 'Marcas',
      '/unidades' => 'Unidades de Medida',
      '/reports' => 'Reportes 606/607',
      '/impuestos' => 'Impuestos',
      '/import-export' => 'Importar / Exportar',
      '/configuracion' => 'Configuración',
      _ when rutaActual.startsWith('/ventas/cotizaciones/') => 'Cotización',
      _ when rutaActual.startsWith('/compras/') => 'Compras',
      _ when rutaActual.startsWith('/inventario-fisico/') => 'Inventario Físico',
      _ when rutaActual.startsWith('/clientes/') => 'Gestión de Cliente',
      _ => 'FiscoGest RD',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    const navWidth = 260.0;
    final currentPath = GoRouterState.of(context).uri.path;
    final tituloPantalla = _obtenerTituloPantalla(currentPath);

    if (isMobile) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          title: Text(
            tituloPantalla,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        drawer: _buildMenu(navWidth, currentPath, context, tituloPantalla),
        body: child,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Row(
        children: [
          SizedBox(
            width: navWidth,
            child: _buildMenu(navWidth, currentPath, context, tituloPantalla),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildMenu(
    double width,
    String currentPath,
    BuildContext context,
    String tituloPantalla,
  ) {
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
                const Icon(
                  Icons.receipt_long,
                  color: Colors.blueAccent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tituloPantalla,
                        style: AppTypography.h3.copyWith(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      Text(
                        'Versión 3.0 Pro',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),
          Expanded(
            child: ListView(
              padding: AppSpacing.vM.copyWith(
                left: AppSpacing.xs,
                right: AppSpacing.xs,
              ),
              children: [
                _buildNavItem(context, '/', 'Dashboard', Icons.dashboard_outlined, currentPath),
                _buildNavItem(context, '/sales', 'Facturación y NC', Icons.point_of_sale_outlined, currentPath),
                _buildNavItem(context, '/ventas', 'Ventas', Icons.point_of_sale, currentPath),
                _buildNavItem(context, '/compras', 'Compras', Icons.shopping_cart_outlined, currentPath),
                _buildNavItem(context, '/inventario', 'Inventario', Icons.inventory_2_outlined, currentPath),
                _buildNavItem(context, '/kardex', 'Kárdex', Icons.receipt_long_outlined, currentPath),
                _buildNavItem(context, '/inventario-fisico', 'Inventario Físico', Icons.inventory_2, currentPath),
                _buildNavItem(context, '/clientes', 'Clientes', Icons.people_outline, currentPath),
                _buildNavItem(context, '/proveedores', 'Proveedores', Icons.business_outlined, currentPath),
                _buildNavItem(context, '/reports', 'Reportes 606/607', Icons.assessment_outlined, currentPath),
                _buildNavItem(context, '/impuestos', 'Impuestos', Icons.calculate_outlined, currentPath),
                _buildNavItem(context, '/import-export', 'Importar / Exportar', Icons.import_export, currentPath),
                _buildNavItem(context, '/configuracion', 'Configuración', Icons.settings_outlined, currentPath),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String routePath,
    String title,
    IconData icon,
    String currentPath,
  ) {
    final esSeleccionado = currentPath == routePath || currentPath.startsWith('$routePath/');

    return Padding(
      padding: AppSpacing.vXs,
      child: Material(
        color: esSeleccionado ? const Color(0xFF1E293B) : Colors.transparent,
        borderRadius: AppRadius.allM,
        child: InkWell(
          borderRadius: AppRadius.allM,
          onTap: () => context.go(routePath),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: esSeleccionado ? Colors.white : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: AppTypography.labelMedium.copyWith(
                      color: esSeleccionado ? Colors.white : AppColors.textSecondary,
                      fontWeight: esSeleccionado ? FontWeight.bold : FontWeight.normal,
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
