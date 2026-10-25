import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/navigation/safe_back.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';

/// Hub de reportes operativos y DGII (606 / 607).
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  static const String routeName = 'reportes-dgii';
  static const String path = '/reports/hub';

  void _abrir(BuildContext context, String tipo) {
    context.push('/reports/detalle/$tipo');
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);

    final operativos = <_ItemReporte>[
      const _ItemReporte(
        codigo: 'VEN',
        titulo: 'Ventas',
        subtitulo: 'Facturas y cobros del período',
        icon: Icons.point_of_sale_outlined,
        color: AppColors.primary,
        tipo: 'ventas',
      ),
      const _ItemReporte(
        codigo: 'COM',
        titulo: 'Compras',
        subtitulo: 'Comprobantes a proveedores',
        icon: Icons.shopping_cart_outlined,
        color: AppColors.info,
        tipo: 'compras',
      ),
      const _ItemReporte(
        codigo: 'UTI',
        titulo: 'Utilidades',
        subtitulo: 'Margen y ganancia bruta',
        icon: Icons.trending_up_rounded,
        color: AppColors.success,
        tipo: 'utilidades',
      ),
      const _ItemReporte(
        codigo: 'PRO',
        titulo: 'Productos',
        subtitulo: 'Más vendidos del período',
        icon: Icons.inventory_2_outlined,
        color: AppColors.warning,
        tipo: 'productos',
      ),
      const _ItemReporte(
        codigo: 'CLI',
        titulo: 'Clientes',
        subtitulo: 'Ventas agrupadas por cliente',
        icon: Icons.people_outline,
        color: AppColors.primary,
        tipo: 'clientes',
      ),
      const _ItemReporte(
        codigo: 'PRV',
        titulo: 'Proveedores',
        subtitulo: 'Compras agrupadas por proveedor',
        icon: Icons.local_shipping_outlined,
        color: Color(0xFF7C3AED),
        tipo: 'proveedores',
      ),
    ];

    return AppScaffold(
      title: 'REPORTES',
      showAppBar: false,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              mobile ? 16 : 24,
              mobile ? 12 : 20,
              mobile ? 16 : 24,
              32,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: mobile ? 720 : 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Atrás',
                        onPressed: () => safeBack(context, fallback: '/reports'),
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                      ),
                      const Text(
                        'Reportes operativos',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _LinkTile(
                    icon: Icons.monitor_heart_outlined,
                    title: 'Dashboard económico',
                    subtitle: 'KPIs de ventas, ganancia y tendencias',
                    onTap: () => safeBack(context, fallback: '/reports'),
                  ),
                  SizedBox(height: mobile ? 18 : 22),
                  Text(
                    'Reportes operativos',
                    style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Consulta movimientos reales de tu negocio por período.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: mobile ? 12 : 16),
                  _GridReportes(
                    items: operativos,
                    mobile: mobile,
                    onTap: (t) => _abrir(context, t),
                  ),
                  SizedBox(height: mobile ? 22 : 28),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemReporte {
  const _ItemReporte({
    required this.codigo,
    required this.titulo,
    required this.subtitulo,
    required this.icon,
    required this.color,
    required this.tipo,
  });
  final String codigo;
  final String titulo;
  final String subtitulo;
  final IconData icon;
  final Color color;
  final String tipo;
}

class _GridReportes extends StatelessWidget {
  const _GridReportes({
    required this.items,
    required this.mobile,
    required this.onTap,
  });
  final List<_ItemReporte> items;
  final bool mobile;
  final void Function(String tipo) onTap;

  @override
  Widget build(BuildContext context) {
    if (mobile) {
      return Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _ReporteCard(item: items[i], onTap: () => onTap(items[i].tipo)),
          ],
        ],
      );
    }
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (final it in items)
          SizedBox(
            width: 300,
            child: _ReporteCard(item: it, onTap: () => onTap(it.tipo)),
          ),
      ],
    );
  }
}

class _ReporteCard extends StatelessWidget {
  const _ReporteCard({required this.item, required this.onTap});
  final _ItemReporte item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(item.icon, color: item.color, size: 24),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.codigo,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: item.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                item.titulo,
                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitulo,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Abrir',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: item.color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: item.color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
