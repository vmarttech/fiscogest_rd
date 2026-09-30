import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const String routeName = 'dashboard';

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── HEADER ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: AppTypography.h2.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Resumen operativo en tiempo real',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (!isMobile)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: AppRadius.allM,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Hoy',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // ─── KPI CARDS ───
              _buildKpiGrid(isMobile),

              const SizedBox(height: 28),

              // ─── CONTENIDO PRINCIPAL ───
              if (isMobile) ...[
                _buildAlertasCard(),
                const SizedBox(height: 20),
                _buildExcepcionesCard(),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildExcepcionesCard()),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: _buildAlertasCard()),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiGrid(bool isMobile) {
    final kpis = [
      const _KpiData(
        title: 'Valor de Inventario',
        value: '\$2,845,760',
        change: '+6.4%',
        isPositive: true,
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.primary,
      ),
      const _KpiData(
        title: 'Alertas Críticas',
        value: '12',
        change: 'Requieren atención',
        isPositive: false,
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
      ),
      const _KpiData(
        title: 'Ventas del Día',
        value: '\$18,392',
        change: '+8.7%',
        isPositive: true,
        icon: Icons.point_of_sale_outlined,
        color: AppColors.success,
      ),
      const _KpiData(
        title: 'Fill Rate',
        value: '92.6%',
        change: '+3.1%',
        isPositive: true,
        icon: Icons.trending_up_rounded,
        color: AppColors.info,
      ),
    ];

    if (isMobile) {
      return Column(
        children: kpis
            .map(
              (kpi) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _KpiCard(data: kpi),
              ),
            )
            .toList(),
      );
    }

    return Row(
      children: kpis
          .map(
            (kpi) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _KpiCard(data: kpi),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildAlertasCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.allL,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alertas Prioritarias',
                style: AppTypography.h4.copyWith(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Ver todas',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _AlertItem(
            title: 'Stock crítico: Mascarillas quirúrgicas',
            subtitle: 'Solo 120 unidades (mínimo 500)',
            level: AlertLevel.critical,
          ),
          const _AlertItem(
            title: 'Reorden recomendado: 12 SKUs',
            subtitle: 'Productos por debajo del punto de reorden',
            level: AlertLevel.warning,
          ),
          const _AlertItem(
            title: 'Discrepancia de conteo',
            subtitle: '2 productos con diferencia en inventario físico',
            level: AlertLevel.info,
          ),
          const _AlertItem(
            title: 'Transferencia pendiente',
            subtitle: 'Almacén Este → Tienda Norte',
            level: AlertLevel.info,
          ),
        ],
      ),
    );
  }

  Widget _buildExcepcionesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.allL,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Excepciones de Inventario',
                style: AppTypography.h4.copyWith(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Ver inventario',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Header de tabla
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Producto', style: _tableHeaderStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Estado', style: _tableHeaderStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Stock', style: _tableHeaderStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Riesgo', style: _tableHeaderStyle),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const _ExceptionRow(
            name: 'Mascarilla quirúrgica 50-pack',
            status: 'Crítico',
            statusColor: AppColors.error,
            stock: '120',
            risk: '\$1,240',
          ),
          const _ExceptionRow(
            name: 'Suero IV 1000ml',
            status: 'Crítico',
            statusColor: AppColors.error,
            stock: '35',
            risk: '\$875',
          ),
          const _ExceptionRow(
            name: 'Paracetamol 500mg',
            status: 'Exceso',
            statusColor: AppColors.warning,
            stock: '12,750',
            risk: '\$2,805',
          ),
          const _ExceptionRow(
            name: 'Guantes de nitrilo 100-pack',
            status: 'Crítico',
            statusColor: AppColors.error,
            stock: '80',
            risk: '\$960',
          ),
          const _ExceptionRow(
            name: 'Cilindro de oxígeno (E)',
            status: 'Exceso',
            statusColor: AppColors.warning,
            stock: '45',
            risk: '\$4,500',
          ),
        ],
      ),
    );
  }

  TextStyle get _tableHeaderStyle => AppTypography.labelSmall.copyWith(
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w600,
  );
}

// ─────────────────────────────────────────────
// MODELOS Y WIDGETS AUXILIARES
// ─────────────────────────────────────────────

class _KpiData {
  const _KpiData({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.color,
  });
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color color;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});
  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.allL,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.color, size: 22),
              ),
              if (data.change.startsWith('+') || data.change.startsWith('-'))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: data.isPositive
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data.change,
                    style: AppTypography.labelSmall.copyWith(
                      color: data.isPositive
                          ? AppColors.success
                          : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data.title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.value,
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!data.change.startsWith('+') && !data.change.startsWith('-')) ...[
            const SizedBox(height: 4),
            Text(
              data.change,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum AlertLevel { critical, warning, info }

class _AlertItem extends StatelessWidget {
  const _AlertItem({
    required this.title,
    required this.subtitle,
    required this.level,
  });
  final String title;
  final String subtitle;
  final AlertLevel level;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (level) {
      AlertLevel.critical => AppColors.error,
      AlertLevel.warning => AppColors.warning,
      AlertLevel.info => AppColors.info,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExceptionRow extends StatelessWidget {
  const _ExceptionRow({
    required this.name,
    required this.status,
    required this.statusColor,
    required this.stock,
    required this.risk,
  });
  final String name;
  final String status;
  final Color statusColor;
  final String stock;
  final String risk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: AppTypography.labelSmall.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              stock,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              risk,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
