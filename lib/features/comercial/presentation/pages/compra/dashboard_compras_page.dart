import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_section.dart';
import 'package:fiscogest_rd/core/ui/app_sizes.dart';
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
          tooltip: 'Notificaciones',
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
          padding: AppLayout.pantallaPadding,
          children: [
            kpisAsync.when(
              data: (kpis) => _KpisGrid(
                comprasEsteMes: currency.format(kpis.comprasEsteMes),
                aCredito: currency.format(kpis.aCreditoEsteMes),
                porPagar: currency.format(kpis.porPagar),
                vencido: currency.format(kpis.vencido),
                hayVencido: kpis.vencido > 0,
              ),
              loading: () => const Padding(
                padding: AppSpacing.vXl,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => AppCard(
                child: Text(
                  'Error cargando KPIs: $e',
                  style: AppTypography.error,
                ),
              ),
            ),
            AppLayout.vL,
            AppSection(
              title: 'Accesos rápidos',
              children: [
                Wrap(
                  spacing: AppSpacing.m,
                  runSpacing: AppSpacing.m,
                  children: [
                    _AccesoRapido(
                      icon: Icons.add_shopping_cart,
                      label: 'Registrar compra',
                      color: AppColors.primary,
                      onTap: () => context.push('/compras/registrar'),
                    ),
                    _AccesoRapido(
                      icon: Icons.list_alt,
                      label: 'Compras',
                      color: AppColors.info,
                      onTap: () => context.push('/compras/lista'),
                    ),
                    _AccesoRapido(
                      icon: Icons.account_balance_wallet,
                      label: 'Cuentas por pagar',
                      color: AppColors.warning,
                      onTap: () => context.goNamed(ListaCuentasPagarPage.routeName),
                      badge: alertas > 0 ? alertas : null,
                    ),
                    _AccesoRapido(
                      icon: Icons.request_quote_outlined,
                      label: 'Cuentas por cobrar',
                      color: AppColors.secondary,
                      onTap: () => context.push('/ventas/cobrar'),
                    ),
                  ],
                ),
              ],
            ),
            AppLayout.vL,
            const Text('Actividad reciente', style: AppTypography.h4),
            AppLayout.vS,
            actividadAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return AppCard(
                    child: Center(
                      child: Text(
                        'No hay compras registradas aún',
                        style: AppTypography.bodyMediumSecondary,
                      ),
                    ),
                  );
                }
                return Column(
                  children: items.map((item) {
                    final fechaStr = _formatearFechaRelativa(item.fecha);
                    return Padding(
                      padding: AppSpacing.bS,
                      child: AppCard(
                        padding: EdgeInsets.zero,
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: AppSpacing.hM,
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              child: const Icon(
                                Icons.shopping_bag_outlined,
                                color: AppColors.primary,
                                size: AppSizes.iconMd,
                              ),
                            ),
                            title: Text(
                              item.proveedorNombre,
                              style: AppTypography.bodyMediumSemiBold,
                            ),
                            subtitle: Text(
                              '$fechaStr · ${_estadoLabel(item.estado)}',
                              style: AppTypography.bodySmall,
                            ),
                            trailing: Text(
                              currency.format(item.total),
                              style: AppTypography.bodyMediumBold,
                            ),
                            onTap: () {
                              context.push(
                                '/compras/detalle/${item.compraId}',
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: AppSpacing.vL,
                child: Center(child: CircularProgressIndicator()),
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
    switch (estado) {
      case EstadoCompra.confirmada:
        return 'Confirmada';
      case EstadoCompra.registrada:
        return 'Registrada';
      case EstadoCompra.recibida:
        return 'Recibida';
      case EstadoCompra.pagada:
        return 'Pagada';
      case EstadoCompra.vencida:
        return 'Vencida';
      case EstadoCompra.borrador:
        return 'Borrador';
      case EstadoCompra.anulada:
        return 'Anulada';
    }
  }
}

class _KpisGrid extends StatelessWidget {
  const _KpisGrid({
    required this.comprasEsteMes,
    required this.aCredito,
    required this.porPagar,
    required this.vencido,
    this.hayVencido = false,
  });

  final String comprasEsteMes;
  final String aCredito;
  final String porPagar;
  final String vencido;
  final bool hayVencido;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.m,
      crossAxisSpacing: AppSpacing.m,
      childAspectRatio: 1.55,
      children: [
        _KpiCard(
          titulo: 'Este mes',
          valor: comprasEsteMes,
          icon: Icons.calendar_month,
          color: AppColors.primary,
        ),
        _KpiCard(
          titulo: 'A crédito',
          valor: aCredito,
          icon: Icons.credit_card,
          color: AppColors.secondary,
        ),
        _KpiCard(
          titulo: 'Por pagar',
          valor: porPagar,
          icon: Icons.pending_actions,
          color: AppColors.warning,
        ),
        _KpiCard(
          titulo: 'Vencido',
          valor: vencido,
          icon: Icons.warning_amber_rounded,
          color: AppColors.error,
          badge: hayVencido,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
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

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: AppSpacing.allM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Badge(
                isLabelVisible: badge,
                smallSize: 8,
                child: Icon(icon, size: AppSizes.iconSm, color: color),
              ),
              AppLayout.hS,
              Expanded(
                child: Text(
                  titulo,
                  style: AppTypography.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            valor,
            style: AppTypography.h4Bold.copyWith(color: color),
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
    return AppCard(
      padding: AppSpacing.vM.add(AppSpacing.hS),
      color: color.withValues(alpha: 0.08),
      borderColor: color.withValues(alpha: 0.2),
      onTap: onTap,
      child: SizedBox(
        width: AppSizes.accesoRapidoWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badge != null && badge! > 0,
              label: badge != null
                  ? Text(
                      '$badge',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.white,
                      ),
                    )
                  : null,
              child: Icon(icon, color: color, size: AppSizes.iconLg),
            ),
            AppLayout.vS,
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.labelSmallSemiBold.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
