import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
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
      '/ventas/cobro' => 'Caja',
      '/creditos' => 'Crédito',
      '/creditos/solicitudes' => 'Solicitudes de crédito',
      '/creditos/cuentas' => 'Cuentas por cobrar',
      '/creditos/config' => 'Configuración crédito',
      '/ventas/cobro/operacion' => 'Cobrar cotización',
      '/ventas/cobro/historial-turno' => 'Movimientos del turno',
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
    const navWidth = 280.0;
    final currentPath = GoRouterState.of(context).uri.path;
    final tituloPantalla = _obtenerTituloPantalla(currentPath);

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(
          backgroundColor: AppColors.sidebarBackground,
          title: Text(
            tituloPantalla,
            style: AppTypography.h4.copyWith(
              color: AppColors.white,
              fontSize: 16,
            ),
          ),
          iconTheme: const IconThemeData(color: AppColors.white),
        ),
        drawer: _buildMenu(navWidth, currentPath, context),
        body: child,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
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
      color: AppColors.sidebarBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── HEADER (Logo + App) ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: AppColors.primaryLight,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FiscoGest RD',
                          style: AppTypography.h4.copyWith(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Gestión Comercial',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.grey400,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.divider, height: 1),

            // ─── MENÚ CON SCROLL (nunca corta el último ítem) ───
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
                children: [
                  _buildSectionTitle('OPERACIONES'),
                  _buildNavItem(context, '/', 'Dashboard', Icons.dashboard_outlined, currentPath),
                  _buildNavItem(context, '/sales', 'Facturación y NC', Icons.point_of_sale_outlined, currentPath),
                  _buildNavItem(context, '/ventas', 'Ventas', Icons.point_of_sale, currentPath),
                  _buildNavItem(context, '/ventas/cobro', 'Caja', Icons.payments_outlined, currentPath),
                  _buildNavItem(context, '/creditos', 'Crédito', Icons.credit_score_outlined, currentPath),
                  _buildNavItem(context, '/compras', 'Compras', Icons.shopping_cart_outlined, currentPath),

                  const SizedBox(height: 18),
                  _buildSectionTitle('INVENTARIO'),
                  _buildNavItem(context, '/inventario', 'Productos', Icons.inventory_2_outlined, currentPath),
                  _buildNavItem(context, '/kardex', 'Kárdex', Icons.receipt_long_outlined, currentPath),
                  _buildNavItem(context, '/inventario-fisico', 'Inventario Físico', Icons.fact_check_outlined, currentPath),
                  _buildNavItem(context, '/lista-ajustes', 'Ajustes', Icons.tune_outlined, currentPath),
                  _buildNavItem(context, '/transferencias/registrar', 'Transferencias', Icons.swap_horiz_outlined, currentPath),

                  const SizedBox(height: 18),
                  _buildSectionTitle('MAESTROS'),
                  _buildNavItem(context, '/clientes', 'Clientes', Icons.people_outline, currentPath),
                  _buildNavItem(context, '/proveedores', 'Proveedores', Icons.business_outlined, currentPath),
                  _buildNavItem(context, '/categorias', 'Categorías', Icons.category_outlined, currentPath),
                  _buildNavItem(context, '/marcas', 'Marcas', Icons.branding_watermark_outlined, currentPath),
                  _buildNavItem(context, '/unidades', 'Unidades', Icons.straighten_outlined, currentPath),
                  _buildNavItem(context, '/presentaciones', 'Presentaciones', Icons.view_module_outlined, currentPath),

                  const SizedBox(height: 18),
                  _buildSectionTitle('ADMINISTRACIÓN'),
                  _buildNavItem(context, '/reports', 'Reportes 606/607', Icons.assessment_outlined, currentPath),
                  _buildNavItem(context, '/impuestos', 'Impuestos', Icons.calculate_outlined, currentPath),
                  _buildNavItem(context, '/import-export', 'Importar / Exportar', Icons.import_export, currentPath),
                  _buildNavItem(context, '/configuracion', 'Configuración', Icons.settings_outlined, currentPath),
                ],
              ),
            ),

            // ─── FOOTER FIJO (siempre visible) ───
            const Divider(color: AppColors.divider, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botón Cerrar sesión
                  Material(
                    color: Colors.transparent,
                    borderRadius: AppRadius.allM,
                    child: InkWell(
                      borderRadius: AppRadius.allM,
                      onTap: () {
                        // TODO: implementar logout real
                        if (AppBreakpoints.isMobile(context)) {
                          Navigator.of(context).pop();
                        }
                        // context.go('/login');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.logout_rounded,
                              color: AppColors.grey400,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Cerrar sesión',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.grey400,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      'v3.0 Pro',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.grey500,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.grey400,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.9,
          fontSize: 10,
        ),
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
    final esSeleccionado =
        currentPath == routePath || currentPath.startsWith('$routePath/');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: esSeleccionado
            ? AppColors.primary.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: AppRadius.allM,
        child: InkWell(
          borderRadius: AppRadius.allM,
          onTap: () {
            if (AppBreakpoints.isMobile(context)) {
              Navigator.of(context).pop();
            }
            context.go(routePath);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: esSeleccionado
                      ? AppColors.primaryLight
                      : AppColors.grey400,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: AppTypography.labelMedium.copyWith(
                      color: esSeleccionado ? AppColors.white : AppColors.grey400,
                      fontWeight:
                          esSeleccionado ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                if (esSeleccionado)
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(2),
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
