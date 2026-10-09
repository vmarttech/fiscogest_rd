import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/compra/dashboard_compras_providers.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/cuentas_pagar/lista_cuentas_pagar_page.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

class DashboardComprasPage extends ConsumerWidget {
  const DashboardComprasPage({super.key});

  static const String routeName = 'dashboard-compras';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(dashboardComprasKpisProvider);
    final actividadAsync = ref.watch(actividadRecienteComprasProvider);
    final isMobile = AppBreakpoints.isMobile(context);
    final desktop = !isMobile;

    final alertas = kpisAsync.maybeWhen(
      data: (k) => k.vencido > 0 ? 1 : 0,
      orElse: () => 0,
    );

    return AppScaffold(
      title: 'COMPRAS',
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(dashboardComprasKpisProvider);
          ref.invalidate(actividadRecienteComprasProvider);
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 24,
            isMobile ? 12 : 20,
            isMobile ? 16 : 24,
            32,
          ),
          children: [
            AppLayout.centerConstrained(
              maxWidth: desktop ? 1100 : 720,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Banner ──
                  _BannerCompras(mobile: isMobile),
                  const SizedBox(height: 18),

                  // ── KPIs pastel ──
                  kpisAsync.when(
                    data: (kpis) => _KpisPastel(
                      comprasEsteMes: formatRd(kpis.comprasEsteMes),
                      aCredito: formatRd(kpis.aCreditoEsteMes),
                      porPagar: formatRd(kpis.porPagar),
                      vencido: formatRd(kpis.vencido),
                      hayVencido: kpis.vencido > 0,
                      isMobile: isMobile,
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                    error: (e, _) => AppCard(
                      child: Text(
                        'Error cargando KPIs: $e',
                        style: AppTypography.error,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Text(
                    'Operaciones',
                    style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Compra, listado y cuentas por pagar',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Ops: 2 grandes + link CxP ──
                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _OpCard(
                            icon: Icons.add_shopping_cart_rounded,
                            title: 'Registrar compra',
                            subtitle: 'Nueva orden de compra a proveedor',
                            color: AppColors.primary,
                            onTap: () => context.push('/compras/registrar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OpCard(
                            icon: Icons.list_alt_rounded,
                            title: 'Lista de compras',
                            subtitle: 'Historial y seguimiento',
                            color: const Color(0xFF6366F1),
                            onTap: () => context.push('/compras/lista'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: TextButton(
                            onPressed: () => context.goNamed(
                              ListaCuentasPagarPage.routeName,
                            ),
                            child: Text(
                              alertas > 0
                                  ? 'Cuentas por pagar · $alertas alerta(s) →'
                                  : 'Cuentas por pagar →',
                              style: AppTypography.labelMedium.copyWith(
                                color: alertas > 0
                                    ? AppColors.warning
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _OpCard(
                      icon: Icons.add_shopping_cart_rounded,
                      title: 'Registrar compra',
                      subtitle: 'Nueva orden de compra a proveedor',
                      color: AppColors.primary,
                      onTap: () => context.push('/compras/registrar'),
                    ),
                    const SizedBox(height: 10),
                    _OpCard(
                      icon: Icons.list_alt_rounded,
                      title: 'Lista de compras',
                      subtitle: 'Historial y seguimiento',
                      color: const Color(0xFF6366F1),
                      onTap: () => context.push('/compras/lista'),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () =>
                          context.goNamed(ListaCuentasPagarPage.routeName),
                      child: Text(
                        alertas > 0
                            ? 'Cuentas por pagar · $alertas alerta(s) →'
                            : 'Cuentas por pagar →',
                        style: AppTypography.labelMedium.copyWith(
                          color: alertas > 0
                              ? AppColors.warning
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Actividad reciente ──
                  Row(
                    children: [
                      Text(
                        'Actividad reciente',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.push('/compras/lista'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Ver todas →',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  actividadAsync.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.shopping_bag_outlined,
                                size: 36,
                                color: AppColors.grey300,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No hay compras registradas aún',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < items.length; i++) ...[
                              if (i > 0)
                                const Divider(
                                  height: 1,
                                  color: AppColors.border,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                              _ActividadRow(
                                proveedor: items[i].proveedorNombre,
                                detalle:
                                    '${_formatearFechaRelativa(items[i].fecha)} · ${_estadoLabel(items[i].estado)}',
                                monto: formatRd(items[i].total),
                                estado: items[i].estado,
                                onTap: () => context.push(
                                  '/compras/detalle/${items[i].compraId}',
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    error: (e, _) =>
                        Text('Error: $e', style: AppTypography.error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFechaRelativa(DateTime fecha) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final ayer = hoy.subtract(const Duration(days: 1));
    final f = DateTime(fecha.year, fecha.month, fecha.day);
    if (f == hoy) return 'Hoy';
    if (f == ayer) return 'Ayer';
    return DateFormat('d MMM', 'es').format(fecha);
  }

  String _estadoLabel(EstadoCompra estado) {
    return switch (estado) {
      EstadoCompra.confirmada => 'Confirmada',
      EstadoCompra.registrada => 'Registrada',
      EstadoCompra.recibida => 'Recibida',
      EstadoCompra.pagada => 'Pagada',
      EstadoCompra.vencida => 'Vencida',
      EstadoCompra.borrador => 'Borrador',
      EstadoCompra.anulada => 'Anulada',
    };
  }
}

// ─────────────────────────────────────────────
class _BannerCompras extends StatelessWidget {
  const _BannerCompras({required this.mobile});
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 18 : 24,
        vertical: mobile ? 16 : 20,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: mobile ? 44 : 52,
            height: mobile ? 44 : 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.shopping_cart_checkout_rounded,
              color: AppColors.primary,
              size: mobile ? 24 : 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Centro de compras',
                  style: (mobile ? AppTypography.h4 : AppTypography.h3).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Registra compras, revisa actividad y controla cuentas por pagar.',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.35,
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

class _KpisPastel extends StatelessWidget {
  const _KpisPastel({
    required this.comprasEsteMes,
    required this.aCredito,
    required this.porPagar,
    required this.vencido,
    required this.isMobile,
    this.hayVencido = false,
  });

  final String comprasEsteMes;
  final String aCredito;
  final String porPagar;
  final String vencido;
  final bool hayVencido;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final items = [
      _PillData(
        icon: Icons.calendar_month_rounded,
        value: comprasEsteMes,
        label: 'ESTE MES',
        bg: const Color(0xFFECFDF5),
        fg: AppColors.success,
      ),
      _PillData(
        icon: Icons.credit_card_rounded,
        value: aCredito,
        label: 'A CRÉDITO',
        bg: const Color(0xFFEFF6FF),
        fg: AppColors.info,
      ),
      _PillData(
        icon: Icons.pending_actions_rounded,
        value: porPagar,
        label: 'POR PAGAR',
        bg: const Color(0xFFFFF7ED),
        fg: AppColors.warning,
      ),
      _PillData(
        icon: Icons.warning_amber_rounded,
        value: vencido,
        label: 'VENCIDO',
        bg: const Color(0xFFFEF2F2),
        fg: AppColors.error,
        badge: hayVencido,
      ),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
        children: items.map((d) => _KpiPill(data: d)).toList(),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _KpiPill(data: items[i])),
        ],
      ],
    );
  }
}

class _PillData {
  const _PillData({
    required this.icon,
    required this.value,
    required this.label,
    required this.bg,
    required this.fg,
    this.badge = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color bg;
  final Color fg;
  final bool badge;
}

class _KpiPill extends StatelessWidget {
  const _KpiPill({required this.data});
  final _PillData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: data.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Badge(
            isLabelVisible: data.badge,
            smallSize: 8,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(data.icon, color: data.fg, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h4.copyWith(
                    fontWeight: FontWeight.w800,
                    color: data.fg,
                    fontSize: 15,
                  ),
                ),
                Text(
                  data.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.4,
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

class _OpCard extends StatelessWidget {
  const _OpCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
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
              const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }
}


class _ActividadRow extends StatelessWidget {
  const _ActividadRow({
    required this.proveedor,
    required this.detalle,
    required this.monto,
    required this.estado,
    required this.onTap,
  });

  final String proveedor;
  final String detalle;
  final String monto;
  final EstadoCompra estado;
  final VoidCallback onTap;

  (String, Color) get _chip {
    return switch (estado) {
      EstadoCompra.confirmada => ('Confirmada', AppColors.success),
      EstadoCompra.registrada => ('Registrada', AppColors.info),
      EstadoCompra.recibida => ('Recibida', AppColors.primary),
      EstadoCompra.pagada => ('Pagada', AppColors.success),
      EstadoCompra.vencida => ('Vencida', AppColors.error),
      EstadoCompra.borrador => ('Borrador', AppColors.grey500),
      EstadoCompra.anulada => ('Anulada', AppColors.error),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (chipLabel, chipColor) = _chip;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proveedor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detalle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  chipLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: chipColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                monto,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
