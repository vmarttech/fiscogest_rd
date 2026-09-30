import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/presentation/widgets/shell_drawer_scope.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/reportes/domain/kpi_models.dart';
import 'package:fiscogest_rd/features/reportes/presentation/providers/dashboard_providers.dart';

class DashboardEconomicoPage extends ConsumerWidget {
  const DashboardEconomicoPage({super.key});

  static final _fmt = NumberFormat('#,##0.00', 'es_DO');
  static final _fmtEntero = NumberFormat('#,##0', 'es_DO');

  String _saludo() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  KpiPeriodo _kpiDe(DashboardSnapshot s, PeriodoDash p) {
    switch (p) {
      case PeriodoDash.hoy:
        return s.hoy;
      case PeriodoDash.semana:
        return s.semana;
      case PeriodoDash.mes:
        return s.mes;
      case PeriodoDash.anio:
        return s.anio;
    }
  }

  String _labelPeriodo(PeriodoDash p) {
    switch (p) {
      case PeriodoDash.hoy:
        return 'Hoy';
      case PeriodoDash.semana:
        return 'Esta semana';
      case PeriodoDash.mes:
        return 'Este mes';
      case PeriodoDash.anio:
        return 'Este año';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);
    final async = ref.watch(dashboardSnapshotProvider);
    final periodo = ref.watch(periodoDashProvider);
    final sesion = ref.watch(sesionProvider);
    final modoSimplificado = ref.watch(modoSimplificadoProvider);
    final nombre = sesion?.nombre.isNotEmpty == true
        ? sesion!.nombre
        : (sesion?.username ?? '');

    return AppScaffold(
      title: 'REPORTES',
      showBackButton: false,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        tooltip: 'Menú',
        onPressed: () => ShellDrawerScope.open(context),
      ),
      actions: [
        if (!modoSimplificado)
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: 'DGII 606/607',
            onPressed: () => context.push('/reports/dgii'),
          ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSnapshotProvider);
          await ref.read(dashboardSnapshotProvider.future);
        },
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No se pudo cargar el dashboard',
                    style: AppTypography.h4,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$e',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(dashboardSnapshotProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
          data: (snap) {
            final kpi = _kpiDe(snap, periodo);
            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  mobile ? 16 : 24,
                  mobile ? 12 : 20,
                  mobile ? 16 : 24,
                  40,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: desktop ? 1100 : (mobile ? 560 : 800),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Hero(
                        saludo:
                            '${_saludo()}${nombre.isNotEmpty ? ', $nombre' : ''}',
                        periodoLabel: _labelPeriodo(periodo),
                        ventas: kpi.ventas,
                        delta: kpi.deltaVentasPct,
                        fmt: _fmt,
                      ),
                      const SizedBox(height: 16),
                      _PeriodoChips(
                        selected: periodo,
                        onChanged: (p) =>
                            ref.read(periodoDashProvider.notifier).state = p,
                      ),
                      const SizedBox(height: 16),
                      _KpiGrid(
                        kpi: kpi,
                        mobile: mobile,
                        fmt: _fmt,
                        fmtEntero: _fmtEntero,
                      ),
                      const SizedBox(height: 20),
                      _ChartCard(serie: snap.serie30Dias, fmt: _fmt),
                      const SizedBox(height: 16),
                      if (mobile) ...[
                        _MixPagoCard(data: snap.porFormaPago, fmt: _fmt),
                        const SizedBox(height: 12),
                        _TopProductosCard(items: snap.topProductos, fmt: _fmt),
                        const SizedBox(height: 12),
                        _SaludCard(kpi: kpi),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _MixPagoCard(
                                data: snap.porFormaPago,
                                fmt: _fmt,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TopProductosCard(
                                items: snap.topProductos,
                                fmt: _fmt,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: _SaludCard(kpi: kpi)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Hero ───────────────────────────────────────────────
class _Hero extends StatelessWidget {
  const _Hero({
    required this.saludo,
    required this.periodoLabel,
    required this.ventas,
    required this.delta,
    required this.fmt,
  });
  final String saludo;
  final String periodoLabel;
  final double ventas;
  final double delta;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final up = delta >= 0;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
            const Color(0xFF0D9488),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            saludo,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ventas · $periodoLabel',
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'RD\$ ${fmt.format(ventas)}',
                  style: AppTypography.h2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      up ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${up ? '+' : ''}${delta.toStringAsFixed(1)}%',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Chips ──────────────────────────────────────────────
class _PeriodoChips extends StatelessWidget {
  const _PeriodoChips({required this.selected, required this.onChanged});
  final PeriodoDash selected;
  final ValueChanged<PeriodoDash> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(PeriodoDash p, String label) {
      final on = selected == p;
      return ChoiceChip(
        label: Text(label),
        selected: on,
        onSelected: (_) => onChanged(p),
        selectedColor: AppColors.primary.withValues(alpha: 0.18),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: on ? AppColors.primary : AppColors.textSecondary,
          fontWeight: on ? FontWeight.w700 : FontWeight.w500,
        ),
        side: BorderSide(
          color: on
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.border.withValues(alpha: 0.6),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(PeriodoDash.hoy, 'Hoy'),
        chip(PeriodoDash.semana, 'Semana'),
        chip(PeriodoDash.mes, 'Mes'),
        chip(PeriodoDash.anio, 'Año'),
      ],
    );
  }
}

// ─── KPI grid ───────────────────────────────────────────
class _KpiGrid extends StatelessWidget {
  const _KpiGrid({
    required this.kpi,
    required this.mobile,
    required this.fmt,
    required this.fmtEntero,
  });
  final KpiPeriodo kpi;
  final bool mobile;
  final NumberFormat fmt;
  final NumberFormat fmtEntero;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiCard(
        label: 'Ventas',
        value: 'RD\$ ${fmt.format(kpi.ventas)}',
        delta: kpi.deltaVentasPct,
        icon: Icons.payments_outlined,
        color: AppColors.primary,
      ),
      _KpiCard(
        label: 'Ganancia bruta',
        value: 'RD\$ ${fmt.format(kpi.ganancia)}',
        delta: kpi.deltaGananciaPct,
        icon: Icons.savings_outlined,
        color: const Color(0xFF059669),
      ),
      _KpiCard(
        label: 'Facturas',
        value: fmtEntero.format(kpi.numFacturas),
        delta: null,
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF7C3AED),
      ),
      _KpiCard(
        label: 'Ticket promedio',
        value: 'RD\$ ${fmt.format(kpi.ticketPromedio)}',
        delta: null,
        icon: Icons.shopping_bag_outlined,
        color: const Color(0xFFD97706),
        subtitle: 'Margen ${kpi.margenPct.toStringAsFixed(1)}%',
      ),
    ];

    if (mobile) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i += 2)
            Padding(
              padding: EdgeInsets.only(bottom: i + 2 < cards.length ? 10 : 0),
              child: Row(
                children: [
                  Expanded(child: cards[i]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: i + 1 < cards.length
                        ? cards[i + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.delta,
    this.subtitle,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double? delta;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const Spacer(),
              if (delta != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (delta! >= 0
                                ? const Color(0xFF059669)
                                : const Color(0xFFDC2626))
                            .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${delta! >= 0 ? '+' : ''}${delta!.toStringAsFixed(0)}%',
                    style: AppTypography.labelSmall.copyWith(
                      color: delta! >= 0
                          ? const Color(0xFF059669)
                          : const Color(0xFFDC2626),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.h4.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Chart ──────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.serie, required this.fmt});
  final List<SeriePunto> serie;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final maxY = serie.isEmpty
        ? 1.0
        : serie.map((e) => e.valor).fold<double>(0, (a, b) => a > b ? a : b);
    final spots = <FlSpot>[
      for (var i = 0; i < serie.length; i++)
        FlSpot(i.toDouble(), serie[i].valor),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ventas · últimos 30 días',
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Solo facturado y crédito',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: serie.every((e) => e.valor == 0)
                ? Center(
                    child: Text(
                      'Sin ventas en el período',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY * 1.15 + 1,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: AppColors.border.withValues(alpha: 0.5),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (v, _) => Text(
                              v >= 1000
                                  ? '${(v / 1000).toStringAsFixed(0)}k'
                                  : v.toStringAsFixed(0),
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 7,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= serie.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  serie[i].label,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (spots) => spots
                              .map(
                                (s) => LineTooltipItem(
                                  'RD\$ ${fmt.format(s.y)}',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.28),
                                AppColors.primary.withValues(alpha: 0.02),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Mix pago ───────────────────────────────────────────
class _MixPagoCard extends StatelessWidget {
  const _MixPagoCard({required this.data, required this.fmt});
  final Map<String, double> data;
  final NumberFormat fmt;

  static const _colors = [
    Color(0xFF0D9488),
    Color(0xFF7C3AED),
    Color(0xFFD97706),
    Color(0xFF2563EB),
    Color(0xFFDC2626),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final total = entries.fold<double>(0, (a, e) => a + e.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Formas de pago',
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Mes en curso',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            Text(
              'Sin datos',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...List.generate(entries.length, (i) {
              final e = entries[i];
              final pct = total <= 0 ? 0.0 : (e.value / total) * 100;
              final c = _colors[i % _colors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.key,
                            style: AppTypography.labelMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        minHeight: 6,
                        backgroundColor: c.withValues(alpha: 0.12),
                        color: c,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─── Top productos ──────────────────────────────────────
class _TopProductosCard extends StatelessWidget {
  const _TopProductosCard({required this.items, required this.fmt});
  final List<TopProducto> items;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top productos',
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Mes en curso',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'Sin datos',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...items.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${p.cantidad.toStringAsFixed(p.cantidad == p.cantidad.roundToDouble() ? 0 : 1)} uds',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'RD\$ ${fmt.format(p.monto)}',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─── Salud ──────────────────────────────────────────────
class _SaludCard extends StatelessWidget {
  const _SaludCard({required this.kpi});
  final KpiPeriodo kpi;

  @override
  Widget build(BuildContext context) {
    Color sem(bool ok, bool warn) => ok
        ? const Color(0xFF059669)
        : warn
        ? const Color(0xFFD97706)
        : const Color(0xFFDC2626);

    final margenOk = kpi.margenPct >= 20;
    final margenWarn = kpi.margenPct >= 10;
    final tendOk = kpi.deltaVentasPct >= 0;
    final ticketOk = kpi.ticketPromedio > 0;

    Widget row(String label, String value, Color c) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: AppTypography.labelMedium)),
            Text(
              value,
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: c,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Salud del negocio',
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Periodo seleccionado',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          row(
            'Margen bruto',
            '${kpi.margenPct.toStringAsFixed(1)}%',
            sem(margenOk, margenWarn),
          ),
          row(
            'Tendencia ventas',
            '${kpi.deltaVentasPct >= 0 ? '+' : ''}${kpi.deltaVentasPct.toStringAsFixed(1)}%',
            sem(tendOk, !tendOk && kpi.deltaVentasPct > -10),
          ),
          row(
            'Actividad',
            kpi.numFacturas > 0 ? 'Con movimiento' : 'Sin facturas',
            sem(ticketOk, false),
          ),
        ],
      ),
    );
  }
}
