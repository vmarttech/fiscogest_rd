import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(dashboardComprasKpisProvider);
              ref.invalidate(actividadRecienteComprasProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardComprasKpisProvider);
          ref.invalidate(actividadRecienteComprasProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ========== KPIs ==========
            kpisAsync.when(
              data: (kpis) => _KpisGrid(
                comprasEsteMes: currency.format(kpis.comprasEsteMes),
                aCredito: currency.format(kpis.aCreditoEsteMes),
                porPagar: currency.format(kpis.porPagar),
                vencido: currency.format(kpis.vencido),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error cargando KPIs: $e'),
              ),
            ),

            const SizedBox(height: 24),

            // ========== Accesos rápidos ==========
            Text(
              'Accesos rápidos',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _AccesoRapido(
                  icon: Icons.add_shopping_cart,
                  label: 'Registrar compra',
                  color: Colors.blue,
                  onTap: () => context.go('/compras/registrar'),
                ),
                _AccesoRapido(
                  icon: Icons.list_alt,
                  label: 'Compras',
                  color: Colors.indigo,
                  onTap: () => context.go('/compras/lista'),
                ),
                _AccesoRapido(
                  icon: Icons.account_balance_wallet,
                  label: 'Cuentas por pagar',
                  color: Colors.orange,
                  onTap: () => context.go('/ventas/pagar'),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ========== Actividad reciente ==========
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Actividad reciente',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.go('/compras/lista'),
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            actividadAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('No hay compras registradas aún'),
                      ),
                    ),
                  );
                }
                return Column(
                  children: items.map((item) {
                    final fechaStr = _formatearFechaRelativa(item.fecha);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.blue,
                          ),
                        ),
                        title: Text(
                          item.proveedorNombre,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('$fechaStr · ${_estadoLabel(item.estado)}'),
                        trailing: Text(
                          currency.format(item.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        onTap: () {
                          context.go('/compras/detalle/${item.compraId}');
                        },
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
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
  });

  final String comprasEsteMes;
  final String aCredito;
  final String porPagar;
  final String vencido;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _KpiCard(
          titulo: 'Este mes',
          valor: comprasEsteMes,
          icon: Icons.calendar_month,
          color: Colors.blue,
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
  });

  final String titulo;
  final String valor;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
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
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
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
