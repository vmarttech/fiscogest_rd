import 'dart:math' show cos, sin;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/presentation/widgets/shell_drawer_scope.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/reportes/domain/kpi_models.dart';
import 'package:fiscogest_rd/features/reportes/presentation/providers/dashboard_providers.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';

class DashboardEconomicoPage extends ConsumerWidget {
  const DashboardEconomicoPage({super.key});



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


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);
    final async = ref.watch(dashboardSnapshotProvider);
    final periodo = ref.watch(periodoDashProvider);

    return AppScaffold(
      title: 'REPORTES',
      showAppBar: false,
      showBackButton: false,
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
                // fondo página reportes design: #f4f6f9 vía Material parent
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: desktop ? 1100 : (mobile ? 560 : 800),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ReportesHeader(
                        onMenu: () => ShellDrawerScope.open(context),
                        onHub: () => context.push('/reports/hub'),
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
                      ),
                      const SizedBox(height: 20),
                      _ChartCard(serie: snap.serie30Dias, kpi: kpi),
                      const SizedBox(height: 16),
                      if (mobile) ...[
                        _MixPagoCard(data: snap.porFormaPago),
                        const SizedBox(height: 12),
                        _TopProductosCard(items: snap.topProductos),
                        const SizedBox(height: 12),
                        _SaludCard(kpi: kpi),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _MixPagoCard(
                                data: snap.porFormaPago,
                                      ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TopProductosCard(
                                items: snap.topProductos,
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



// ─── Design tokens (réplica mock reportes) ─────────────
const _kTealBright = Color(0xFF00A896);
const _kInk = Color(0xFF0F172A);
const _kMuted = Color(0xFF334155);
const _kMuted2 = Color(0xFF64748B);
const _kBorder = Color(0xFFCBD5E1);
const _kCardBg = Color(0xFFFFFFFF);
const _kKhaki = Color(0xFFBFA15F);
const _kBlueBar = Color(0xFF2563EB);
const _kNavy = Color(0xFF0D1E34);

// ─── Barra de control: tabs + fechas + comparar (una sola franja) ───

class _ReportesHeader extends StatelessWidget {
  const _ReportesHeader({
    required this.onMenu,
    required this.onHub,
  });
  final VoidCallback onMenu;
  final VoidCallback onHub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF00796B),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00796B).withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenu,
            icon: const Icon(Icons.menu, color: Colors.white),
            tooltip: 'Menú',
          ),
          const Text(
            'REPORTES',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onHub,
            icon: const Icon(Icons.folder_open_outlined, color: Colors.white),
            tooltip: 'Reportes operativos',
          ),
        ],
      ),
    );
  }
}

class _PeriodoChips extends ConsumerWidget {
  const _PeriodoChips({required this.selected, required this.onChanged});
  final PeriodoDash selected;
  final ValueChanged<PeriodoDash> onChanged;

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} de ${d.month.toString().padLeft(2, '0')} de ${d.year}';

  Future<void> _pickRango(BuildContext context, WidgetRef ref) async {
    final actual = ref.read(rangoDashProvider);
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(start: actual.$1, end: actual.$2),
      helpText: 'Rango del reporte',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      builder: (ctx, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        );
      },
    );
    if (picked == null) return;
    final a = DateTime(picked.start.year, picked.start.month, picked.start.day);
    final b = DateTime(picked.end.year, picked.end.month, picked.end.day);
    ref.read(rangoDashProvider.notifier).state = (a, b);
    final days = b.difference(a).inDays;
    if (days <= 0) {
      onChanged(PeriodoDash.hoy);
    } else if (days <= 7) {
      onChanged(PeriodoDash.semana);
    } else if (days <= 31) {
      onChanged(PeriodoDash.mes);
    } else {
      onChanged(PeriodoDash.anio);
    }
  }

  void _syncRangoDesdeChip(WidgetRef ref, PeriodoDash p) {
    final n = DateTime.now();
    final hoy = DateTime(n.year, n.month, n.day);
    late final DateTime a;
    late final DateTime b;
    switch (p) {
      case PeriodoDash.hoy:
        a = hoy;
        b = hoy;
      case PeriodoDash.semana:
        a = hoy.subtract(Duration(days: hoy.weekday - 1));
        b = hoy;
      case PeriodoDash.mes:
        a = DateTime(hoy.year, hoy.month, 1);
        b = hoy;
      case PeriodoDash.anio:
        a = DateTime(hoy.year, 1, 1);
        b = hoy;
    }
    ref.read(rangoDashProvider.notifier).state = (a, b);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rango = ref.watch(rangoDashProvider);
    final comparar = ref.watch(compararDashProvider);

    Widget chip(PeriodoDash p, String label) {
      final on = selected == p;
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Material(
          color: on ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          elevation: on ? 1 : 0,
          shadowColor: Colors.black26,
          child: InkWell(
            onTap: () {
              onChanged(p);
              _syncRangoDesdeChip(ref, p);
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (on) ...[
                    const Icon(Icons.check, size: 14, color: _kInk),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: on ? _kInk : _kMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    String labelComparar(CompararCon c) {
      switch (c) {
        case CompararCon.periodoPrevio:
          return 'Periodo Previo';
        case CompararCon.mesAnterior:
          return 'Mes Anterior';
        case CompararCon.anioAnterior:
          return 'Año Anterior (Periodo Previo)';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                chip(PeriodoDash.hoy, 'Hoy'),
                chip(PeriodoDash.semana, 'Semana'),
                chip(PeriodoDash.mes, 'Mes'),
                chip(PeriodoDash.anio, 'Año'),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: () => _pickRango(context, ref),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF0F172A)),
                    const SizedBox(width: 8),
                    Text(
                      '${_fmt(rango.$1)} — ${_fmt(rango.$2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Text(
            'Comparar con',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          PopupMenuButton<CompararCon>(
            tooltip: 'Base de comparación',
            initialValue: comparar,
            onSelected: (v) =>
                ref.read(compararDashProvider.notifier).state = v,
            itemBuilder: (ctx) => [
              for (final c in CompararCon.values)
                PopupMenuItem(
                  value: c,
                  child: Text(
                    labelComparar(c),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(6),
                color: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    labelComparar(comparar),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.expand_more, size: 18, color: Color(0xFF0F172A)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpi, required this.mobile});
  final KpiPeriodo kpi;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiCard(
        label: 'Ventas',
        value: formatRd(kpi.ventas),
        delta: kpi.deltaVentasPct,
        featured: true,
        subtitle: 'vs. Periodo Anterior',
        spark: true,
      ),
      _KpiCard(
        label: 'Ganancia bruta',
        value: formatRd(kpi.ganancia),
        delta: kpi.deltaGananciaPct,
      ),
      _KpiCard(
        label: 'Gastos',
        value: formatRd(kpi.gastos),
        delta: kpi.deltaGastosPct,
        valueColor: const Color(0xFFB91C1C),
      ),
      _KpiCard(
        label: 'Ganancia neta',
        value: formatRd(kpi.gananciaNeta),
        delta: kpi.deltaGananciaNetaPct,
        subtitle: 'Margen: ${kpi.margenNetoPct.toStringAsFixed(1)}%',
        valueColor: const Color(0xFF1D4ED8),
      ),
    ];
    if (mobile) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            cards[i],
          ],
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
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
    this.delta,
    this.subtitle,
    this.featured = false,
    this.spark = false,
    this.valueColor,
  });
  final String label;
  final String value;
  final double? delta;
  final String? subtitle;
  final bool featured;
  final bool spark;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final up = (delta ?? 0) >= 0;

    if (featured) {
      return Container(
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A1628),
              Color(0xFF0D1E34),
              Color(0xFF0F4C4A),
              Color(0xFF0F766E),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: _kNavy.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (spark)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 40,
                child: CustomPaint(painter: _SparklinePainter()),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const Spacer(),
                    if (delta != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: up
                              ? const Color(0xFFDCFCE7).withValues(alpha: 0.25)
                              : const Color(0xFFFEE2E2).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${up ? '+' : ''}${delta!.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: up ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kMuted,
                ),
              ),
              const Spacer(),
              if (delta != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: up ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${up ? '+' : ''}${delta!.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: up ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor ?? _kInk,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: const TextStyle(fontSize: 11, color: _kMuted2)),
          ],
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final pts = [0.2, 0.45, 0.3, 0.7, 0.4, 0.85, 0.55, 0.65, 0.9];
    for (var i = 0; i < pts.length; i++) {
      final x = w * i / (pts.length - 1);
      final y = h * (1 - pts[i] * 0.85);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = const Color(0xFF00A896).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
    final fill = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF00A896).withValues(alpha: 0.25),
            const Color(0xFF00A896).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Chart + Previsión ──────────────────────────────────
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.serie, required this.kpi});
  final List<SeriePunto> serie;
  final KpiPeriodo kpi;

  @override
  Widget build(BuildContext context) {
    final maxY = serie.isEmpty
        ? 1.0
        : serie.map((e) => e.valor).fold<double>(0, (a, b) => a > b ? a : b);
    final spotsV = <FlSpot>[
      for (var i = 0; i < serie.length; i++) FlSpot(i.toDouble(), serie[i].valor),
    ];
    // Margen como 2ª serie en eje derecho (escala 0–40% mapeada a maxY visual vía right axis)
    final margenBase = kpi.margenPct.clamp(0, 40);
    final spotsM = <FlSpot>[
      for (var i = 0; i < serie.length; i++)
        FlSpot(
          i.toDouble(),
          // onda suave alrededor del margen del periodo (solo visual del mock)
          (margenBase + (i % 5 - 2) * 1.2).clamp(0, 40),
        ),
    ];

    final mobile = MediaQuery.sizeOf(context).width < 700;

    final chart = SizedBox(
      height: 260,
      child: serie.isEmpty || serie.every((e) => e.valor == 0)
          ? const Center(child: Text('Sin ventas en el período', style: TextStyle(color: _kMuted)))
          : LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY * 1.15 + 1,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) {
                        // etiquetas % margen aprox
                        final pct = maxY <= 0 ? 0.0 : (v / (maxY * 1.15)) * 40;
                        if (v <= 0) return const SizedBox.shrink();
                        return Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: const TextStyle(color: _kMuted2, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (v, _) => Text(
                        v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toStringAsFixed(0),
                        style: const TextStyle(color: _kMuted2, fontSize: 11),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (serie.length / 5).clamp(1, 10).toDouble(),
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= serie.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(serie[i].label, style: const TextStyle(color: _kMuted2, fontSize: 11)),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0D1E34),
                    getTooltipItems: (touched) => touched.map((s) {
                      if (s.barIndex == 1) {
                        return LineTooltipItem(
                          'Margen: ${s.y.toStringAsFixed(0)}%',
                          const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        );
                      }
                      return LineTooltipItem(
                        'Ventas: ${formatRd(s.y)}',
                        const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spotsV,
                    isCurved: true,
                    color: _kTealBright,
                    barWidth: 5.0,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _kTealBright.withValues(alpha: 0.3),
                          _kTealBright.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Margen (khaki) — escala visual secundaria: mapeo a altura del chart
                  LineChartBarData(
                    spots: [
                      for (final s in spotsM)
                        FlSpot(s.x, (s.y / 40) * (maxY * 1.15 + 1)),
                    ],
                    isCurved: true,
                    color: _kKhaki,
                    barWidth: 4.0,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _kKhaki.withValues(alpha: 0.45),
                          _kKhaki.withValues(alpha: 0.18),
                          _kKhaki.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );

    final prevision = _PrevisionPanel(serie: serie);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ventas vs. Margen - Tendencia de 30 Días',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kInk),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Análisis dinámico comparativo',
                      style: TextStyle(fontSize: 12, color: _kMuted),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _LegendDot(color: _kTealBright, label: 'Ventas'),
                  SizedBox(width: 14),
                  _LegendDot(color: _kKhaki, label: 'Margen Bruto'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (mobile) ...[
            chart,
            const SizedBox(height: 16),
            prevision,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: chart),
                const SizedBox(width: 16),
                SizedBox(width: 200, child: prevision),
              ],
            ),
        ],
      ),
    );
  }
}

class _PrevisionPanel extends StatelessWidget {
  const _PrevisionPanel({required this.serie});
  final List<SeriePunto> serie;


  static const _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];
  static const _mesesCorto = [
    'Ene.', 'Feb.', 'Mar.', 'Abr.', 'May.', 'Jun.',
    'Jul.', 'Ago.', 'Sep.', 'Oct.', 'Nov.', 'Dic.',
  ];

  /// Siempre el mes calendario siguiente al actual.
  String get _mesSiguiente {
    final n = DateTime.now();
    final next = DateTime(n.year, n.month + 1, 1);
    return _meses[next.month - 1];
  }

  String get _mesCorto {
    final n = DateTime.now();
    final next = DateTime(n.year, n.month + 1, 1);
    return _mesesCorto[next.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    // Barras visuales a partir de la serie (patrón del mock)
    final vals = serie.isEmpty
        ? [20.0, 25.0, 28.0, 32.0, 35.0]
        : List<double>.generate(5, (i) {
            final idx = (serie.length * (i + 1) / 6).floor().clamp(0, serie.length - 1);
            return serie[idx].valor;
          });
    final maxV = vals.fold<double>(0, (a, b) => a > b ? a : b) + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Previsión para $_mesSiguiente',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _kInk),
        ),
        const SizedBox(height: 2),
        const Text(
          'Histórica vendida vs. previsión',
          style: TextStyle(fontSize: 10, color: _kMuted2),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < vals.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: (vals[i] / maxV).clamp(0.08, 1.0),
                            widthFactor: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: i == vals.length - 1
                                    ? _kTealBright
                                    : const Color(0xFF94A3B8).withValues(alpha: 0.45),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_mesCorto, style: const TextStyle(fontSize: 9, color: _kMuted2)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kInk)),
      ],
    );
  }
}

// ─── Formas de pago ─────────────────────────────────────
class _MixPagoCard extends StatelessWidget {
  const _MixPagoCard({required this.data});
  final Map<String, double> data;

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final total = entries.fold<double>(0, (a, e) => a + e.value);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Formas de pago', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kInk)),
          const Text('Mes en curso', style: TextStyle(fontSize: 11, color: _kMuted2)),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            const Text('Sin datos', style: TextStyle(color: _kMuted))
          else
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                        Text(
                          '${total <= 0 ? 0 : ((e.value / total) * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: total <= 0 ? 0 : (e.value / total).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: _kBorder,
                        color: _kBlueBar,
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

// ─── Top productos ──────────────────────────────────────
class _TopProductosCard extends StatelessWidget {
  const _TopProductosCard({required this.items});
  final List<TopProducto> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top productos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kInk)),
          const Text('Mes en curso', style: TextStyle(fontSize: 11, color: _kMuted2)),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Text('Sin datos', style: TextStyle(color: _kMuted))
          else
            for (var i = 0; i < items.length && i < 5; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7DD3FC),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0369A1))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[i].nombre,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Cantidad Vendida: ${items[i].cantidad.toStringAsFixed(0)} uds',
                            style: const TextStyle(fontSize: 11, color: _kMuted),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatRd(items[i].monto), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _kInk)),
                        const Text('VENTAS', style: TextStyle(fontSize: 10, color: _kMuted2)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}

// ─── Salud + gauges ─────────────────────────────────────
class _SaludCard extends StatelessWidget {
  const _SaludCard({required this.kpi});
  final KpiPeriodo kpi;

  @override
  Widget build(BuildContext context) {
    final margen = kpi.margenNetoPct;
    final crec = kpi.deltaVentasPct;
    final ok = margen >= 15 && crec >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Salud del negocio', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kInk)),
          const Text('Periodo seleccionado', style: TextStyle(fontSize: 11, color: _kMuted2)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _GaugeBox(valueLabel: '${margen.toStringAsFixed(1)}%', desc: 'Margen bruto', progress: (margen / 40).clamp(0.0, 1.0), color: const Color(0xFFF59E0B))),
              Expanded(child: _GaugeBox(valueLabel: '${crec >= 0 ? '+' : ''}${crec.toStringAsFixed(1)}%', desc: 'Crecimiento de Ventas', progress: ((crec + 20) / 40).clamp(0.0, 1.0), color: const Color(0xFF10B981))),
              Expanded(child: _GaugeBox(valueLabel: ok ? 'Saludable' : 'Atención', desc: 'Cash Flow Index', progress: ok ? 0.85 : 0.4, color: ok ? const Color(0xFFF59E0B) : const Color(0xFFEF4444))),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugeBox extends StatelessWidget {
  const _GaugeBox({required this.valueLabel, required this.desc, required this.progress, required this.color});
  final String valueLabel;
  final String desc;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 70,
          height: 40,
          child: CustomPaint(
            painter: _ArcGaugePainter(progress: progress, color: color),
          ),
        ),
        const SizedBox(height: 4),
        Text(valueLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _kInk), textAlign: TextAlign.center),
        Text(desc, style: const TextStyle(fontSize: 10, color: _kMuted), textAlign: TextAlign.center),
      ],
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  _ArcGaugePainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height - 2);
    final r = size.width * 0.42;
    const start = 3.141592653589793;
    const sweep = 3.141592653589793;
    final p = progress.clamp(0.0, 1.0);

    final bg = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, sweep, false, bg);

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      start,
      sweep * p,
      false,
      fg,
    );

    final angle = start + sweep * p;
    final needleLen = r - 2;
    final nx = c.dx + needleLen * cos(angle);
    final ny = c.dy + needleLen * sin(angle);
    canvas.drawLine(
      c,
      Offset(nx, ny),
      Paint()
        ..color = const Color(0xFF0F172A)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(c, 4.5, Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(c, 2.2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _ArcGaugePainter old) =>
      old.progress != progress || old.color != color;
}
