import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
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

    final currency = NumberFormat.currency(
      locale: 'es_DO',
      symbol: 'RD\$ ',
      decimalDigits: 0,
    );

    final alertas = kpisAsync.maybeWhen(
      data: (k) => k.vencido > 0 ? 1 : 0,
      orElse: () => 0,
    );

    return AppScaffold(
      title: 'Compras',
      actions: [
        IconButton(
          tooltip: 'Cuentas por pagar',
          onPressed: () => context.goNamed(ListaCuentasPagarPage.routeName),
          icon: Badge(
            isLabelVisible: alertas > 0,
            label: Text(
              '$alertas',
              style: AppTypography.labelSmall.copyWith(color: AppColors.white),
            ),
            child: const Icon(Icons.notifications_outlined),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
          onPressed: () {
            ref.invalidate(dashboardComprasKpisProvider);
            ref.invalidate(actividadRecienteComprasProvider);
          },
        ),
      ],
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(dashboardComprasKpisProvider);
          ref.invalidate(actividadRecienteComprasProvider);
        },
        child: ListView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          children: [
            // ─── HEADER ───
            Text(
              'Dashboard de Compras',
              style: AppTypography.h2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Resumen de compras, pagos y actividad reciente',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // ─── KPIs ───
            kpisAsync.when(
              data: (kpis) => _KpisGrid(
                comprasEsteMes: currency.format(kpis.comprasEsteMes),
                aCredito: currency.format(kpis.aCreditoEsteMes),
                porPagar: currency.format(kpis.porPagar),
                vencido: currency.format(kpis.vencido),
                hayVencido: kpis.vencido > 0,
                isMobile: isMobile,
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (e, _) => AppCard(
                child: Text(
                  'Error cargando KPIs: $e',
                  style: AppTypography.error,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ─── ACCESOS RÁPIDOS ───
            Text(
              'Accesos rápidos',
              style: AppTypography.h4.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _AccesoRapido(
                  icon: Icons.add_shopping_cart_rounded,
                  label: 'Registrar\ncompra',
                  color: AppColors.primary,
                  onTap: () => context.push('/compras/registrar'),
                ),
                _AccesoRapido(
                  icon: Icons.list_alt_rounded,
                  label: 'Lista de\ncompras',
                  color: AppColors.info,
                  onTap: () => context.push('/compras/lista'),
                ),
                _AccesoRapido(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Cuentas\npor pagar',
                  color: AppColors.warning,
                  onTap: () => context.goNamed(ListaCuentasPagarPage.routeName),
                  badge: alertas > 0 ? alertas : null,
                ),
                _AccesoRapido(
                  icon: Icons.request_quote_outlined,
                  label: 'Cuentas\npor cobrar',
                  color: AppColors.secondary,
                  onTap: () => context.push('/ventas/cobrar'),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ─── ACTIVIDAD RECIENTE ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Actividad reciente',
                  style: AppTypography.h4.copyWith(fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () => context.push('/compras/lista'),
                  child: Text(
                    'Ver todas',
                    style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            actividadAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: AppRadius.allL,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 40, color: AppColors.grey300),
                        const SizedBox(height: 12),
                        Text(
                          'No hay compras registradas aún',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.allL,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final fechaStr = _formatearFechaRelativa(item.fecha);
                      final isLast = index == items.length - 1;

                      return Column(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => context.push('/compras/detalle/${item.compraId}'),
                              borderRadius: BorderRadius.vertical(
                                top: index == 0 ? const Radius.circular(12) : Radius.zero,
                                bottom: isLast ? const Radius.circular(12) : Radius.zero,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.shopping_bag_outlined,
                                        color: AppColors.primary,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.proveedorNombre,
                                            style: AppTypography.bodyMedium.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$fechaStr · ${_estadoLabel(item.estado)}',
                                            style: AppTypography.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      currency.format(item.total),
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (!isLast)
                            const Divider(height: 1, color: AppColors.border, indent: 72),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (e, _) => Text('Error: $e', style: AppTypography.error),
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
class _KpisGrid extends StatelessWidget {
  const _KpisGrid({
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
    final cards = [
      _KpiData(
        titulo: 'Este mes',
        valor: comprasEsteMes,
        icon: Icons.calendar_month_rounded,
        color: AppColors.primary,
      ),
      _KpiData(
        titulo: 'A crédito',
        valor: aCredito,
        icon: Icons.credit_card_rounded,
        color: AppColors.secondary,
      ),
      _KpiData(
        titulo: 'Por pagar',
        valor: porPagar,
        icon: Icons.pending_actions_rounded,
        color: AppColors.warning,
      ),
      _KpiData(
        titulo: 'Vencido',
        valor: vencido,
        icon: Icons.warning_amber_rounded,
        color: AppColors.error,
        badge: hayVencido,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _KpiCard(data: c),
                ))
            .toList(),
      );
    }

    return Row(
      children: cards
          .map((c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _KpiCard(data: c),
                ),
              ))
          .toList(),
    );
  }
}

class _KpiData {

  const _KpiData({
    required this.titulo,
    required this.valor,
    required this.icon,
    required this.color,
    this.badge = false,
  });
  final String titulo;
  final String valor;
  final IconData icon;
  final Color color;
  final bool badge;
}

class _KpiCard extends StatelessWidget {

  const _KpiCard({required this.data});
  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.allL,
        border: Border.all(color: AppColors.border),
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
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Badge(
                  isLabelVisible: data.badge,
                  smallSize: 8,
                  child: Icon(data.icon, size: 20, color: data.color),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.titulo,
                  style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data.valor,
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AccesoRapido extends StatelessWidget {
  const _AccesoRapido({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: AppRadius.allL,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allL,
        child: Container(
          width: 110,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: AppRadius.allL,
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: badge != null && badge! > 0,
                label: badge != null
                    ? Text(
                        '$badge',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.white),
                      )
                    : null,
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
