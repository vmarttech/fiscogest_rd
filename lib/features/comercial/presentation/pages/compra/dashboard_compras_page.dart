import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_section.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/compra/dashboard_compras_providers.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

class DashboardComprasPage extends ConsumerWidget {
  const DashboardComprasPage({super.key});

  static const String routeName = 'dashboard-compras';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(dashboardComprasKpisProvider);
    final actividadAsync = ref.watch(actividadRecienteComprasProvider);
    final currency =
        NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$ ', decimalDigits: 0);

    // Badge de alertas = hay monto vencido
    final alertas = kpisAsync.maybeWhen(
      data: (k) => k.vencido > 0 ? 1 : 0,
      orElse: () => 0,
    );

    return AppScaffold(
      title: 'Compras',
      actions: [
        IconButton(
          tooltip: 'Notificaciones',
          onPressed: () => context.push('/ventas/pagar'),
          icon: Badge(
            isLabelVisible: alertas > 0,
            label: Text('$alertas'),
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
        onRefresh: () async {
          ref.invalidate(dashboardComprasKpisProvider);
          ref.invalidate(actividadRecienteComprasProvider);
        },
        child: ListView(
          padding: AppLayout.pantallaPadding,
          children: [
            // ========== KPIs ==========
            kpisAsync.when(
              data: (kpis) => _KpisGrid(
                comprasEsteMes: currency.format(kpis.comprasEsteMes),
                aCredito: currency.format(kpis.aCreditoEsteMes),
                porPagar: currency.format(kpis.porPagar),
                vencido: currency.format(kpis.vencido),
                hayVencido: kpis.vencido > 0,
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Text('Error cargando KPIs: $e'),
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            // ========== Accesos rápidos ==========
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
                      color: Colors.indigo,
                      onTap: () => context.push('/compras/lista'),
                    ),
                    _AccesoRapido(
                      icon: Icons.account_balance_wallet,
                      label: 'Cuentas por pagar',
                      color: Colors.orange,
                      onTap: () => context.push('/ventas/pagar'),
                      badge: alertas > 0 ? alertas : null,
                    ),
                    _AccesoRapido(
                      icon: Icons.request_quote_outlined,
                      label: 'Cuentas por cobrar',
                      color: Colors.teal,
                      onTap: () => context.push('/ventas/cobrar'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.l),

            // ========== Actividad reciente ==========
            Text(
              'Actividad reciente',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.s),

            actividadAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const AppCard(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.l),
                      child: Center(
                        child: Text('No hay compras registradas aún'),
                      ),
                    ),
                  );
                }
                return Column(
                  children: items.map((item) {
                    final fechaStr = _formatearFechaRelativa(item.fecha);
                    return AppCard(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          item.proveedorNombre,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle:
                            Text('$fechaStr · ${_estadoLabel(item.estado)}'),
                        trailing: Text(
                          currency.format(item.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        onTap: () {
                          context.push('/compras/detalle/${item.compraId}');
                        },
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.l),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Error: $e'),
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

// ---------- Widgets privados ----------

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
          color: Colors.purple,
        ),
        _KpiCard(
          titulo: 'Por pagar',
          valor: porPagar,
          icon: Icons.pending_actions,
          color: Colors.orange,
        ),
        _KpiCard(
          titulo: 'Vencido',
          valor: vencido,
          icon: Icons.warning_amber_rounded,
          color: Colors.red,
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Badge(
                  isLabelVisible: badge,
                  smallSize: 8,
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              valor,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.m,
          horizontal: AppSpacing.s,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Badge(
              isLabelVisible: badge != null && badge! > 0,
              label: badge != null ? Text('$badge') : null,
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
