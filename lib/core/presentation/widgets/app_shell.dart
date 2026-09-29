import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/presentation/widgets/shell_drawer_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modoSimplificado = ref.watch(modoSimplificadoProvider);
    final cfg = ref.watch(configuracionControllerProvider).valueOrNull;
    final nombreEmpresa = (cfg?.nombreComercial.trim().isNotEmpty == true)
        ? cfg!.nombreComercial.trim()
        : 'Mi negocio';

    const navWidth = 280.0;
    final currentPath = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      drawer: SizedBox(
        width: navWidth,
        child: _buildMenu(
          navWidth,
          currentPath,
          context,
          nombreEmpresa,
          modoSimplificado,
        ),
      ),
      body: Builder(
        builder: (scaffoldContext) {
          return ShellDrawerScope(
            openDrawer: () {
              final s = Scaffold.maybeOf(scaffoldContext);
              if (s != null && s.hasDrawer) s.openDrawer();
            },
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildMenu(double width, String currentPath, BuildContext context, String nombreEmpresa, bool modoSimplificado) {
    return Material(
      color: AppColors.sidebarBackground,
      child: SizedBox(
        width: width,
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
                            nombreEmpresa,
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
              // ─── MENÚ CON SCROLL ───
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
                  children: [
                    _buildSectionTitle('OPERACIONES'),
                    _buildNavItem(
                      context,
                      '/',
                      modoSimplificado ? 'Inicio' : 'Dashboard',
                      Icons.home_outlined,
                      currentPath,
                    ),
                    if (!modoSimplificado)
                      _buildNavItem(context, '/sales', 'Facturación y NC', Icons.point_of_sale_outlined, currentPath),
                    _buildNavItem(context, '/ventas', 'Ventas', Icons.point_of_sale, currentPath),
                    _buildNavItem(context, '/ventas/cobro', 'Caja', Icons.payments_outlined, currentPath),
                    if (modoSimplificado)
                      _buildNavItem(context, '/ventas/fios', 'Fiao', Icons.edit_note_rounded, currentPath),
                    if (!modoSimplificado)
                      _buildNavItem(context, '/creditos', 'Crédito', Icons.credit_score_outlined, currentPath),
                    _buildNavItem(context, '/compras', 'Compras', Icons.shopping_cart_outlined, currentPath),
                    const SizedBox(height: 18),
                    _buildSectionTitle('INVENTARIO'),
                    _buildNavItem(context, '/inventario', 'Productos', Icons.inventory_2_outlined, currentPath),
                    if (!modoSimplificado) ...[
                      _buildNavItem(context, '/kardex', 'Kárdex', Icons.receipt_long_outlined, currentPath),
                      _buildNavItem(context, '/inventario-fisico', 'Inventario Físico', Icons.fact_check_outlined, currentPath),
                      _buildNavItem(context, '/lista-ajustes', 'Ajustes', Icons.tune_outlined, currentPath),
                      _buildNavItem(context, '/transferencias/registrar', 'Transferencias', Icons.swap_horiz_outlined, currentPath),
                    ],
                    const SizedBox(height: 18),
                    _buildSectionTitle('CATÁLOGOS'),
                    _buildNavItem(context, '/clientes', 'Clientes', Icons.people_outline, currentPath),
                    _buildNavItem(context, '/proveedores', 'Proveedores', Icons.business_outlined, currentPath),
                    _buildNavItem(context, '/categorias', 'Categorías', Icons.category_outlined, currentPath),
                    _buildNavItem(context, '/marcas', 'Marcas', Icons.branding_watermark_outlined, currentPath),
                    _buildNavItem(context, '/unidades', 'Unidades', Icons.straighten_outlined, currentPath),
                    _buildNavItem(context, '/presentaciones', 'Presentaciones', Icons.view_module_outlined, currentPath),
                    const SizedBox(height: 18),
                    _buildSectionTitle('SISTEMA'),
                    if (!modoSimplificado) ...[
                      _buildNavItem(context, '/reports', 'Reportes 606/607', Icons.assessment_outlined, currentPath),
                      _buildNavItem(context, '/impuestos', 'Impuestos', Icons.calculate_outlined, currentPath),
                      _buildNavItem(context, '/import-export', 'Importar / Exportar', Icons.import_export, currentPath),
                    ],
                    _buildNavItem(context, '/configuracion', 'Configuración', Icons.settings_outlined, currentPath),
                  ],
                ),
              ),
              // ─── PIE ───
              const Divider(color: AppColors.divider, height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
            if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
              Navigator.of(context).pop();
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.push(routePath);
            });
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
