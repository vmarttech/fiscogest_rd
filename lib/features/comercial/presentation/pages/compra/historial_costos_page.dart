import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/compra/historial_costos_providers.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/historial_costo.dart';

class HistorialCostosPage extends ConsumerWidget {
  const HistorialCostosPage({super.key, required this.productoId});

  static const String routeName = 'historial-costos';

  final int productoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(historialCostosProvider(productoId));
    final currency =
        NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$ ', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Costos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(historialCostosProvider(productoId)),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (HistorialCostoResumen resumen) {
          if (resumen.items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hay compras registradas para este producto.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                resumen.nombreProducto,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _ResumenCostos(
                ultimo: currency.format(resumen.ultimoCosto),
                promedio: currency.format(resumen.costoPromedio),
                variacion: resumen.variacion,
                variacionPct: resumen.variacionPorcentaje,
                currency: currency,
              ),
              const SizedBox(height: 24),
              Text(
                'Historial',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...resumen.items.map((item) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade50,
                      child: const Icon(Icons.attach_money, color: Colors.indigo),
                    ),
                    title: Text(
                      currency.format(item.costoAdquisicion),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${item.proveedorNombre}\n'
                      '${DateFormat('dd/MM/yyyy').format(item.fecha)}'
                      '${item.ncf.isNotEmpty ? ' · ${item.ncf}' : ''}',
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      'x${item.cantidad.toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    onTap: () {
                      context.go('/compras/detalle/${item.compraId}');
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _ResumenCostos extends StatelessWidget {
  const _ResumenCostos({
    required this.ultimo,
    required this.promedio,
    required this.variacion,
    required this.variacionPct,
    required this.currency,
  });

  final String ultimo;
  final String promedio;
  final double variacion;
  final double variacionPct;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final colorVar = variacion > 0
        ? Colors.red
        : variacion < 0
            ? Colors.green
            : Colors.grey;

    final iconVar = variacion > 0
        ? Icons.trending_up
        : variacion < 0
            ? Icons.trending_down
            : Icons.trending_flat;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _KpiMini(
                    label: 'Último costo',
                    value: ultimo,
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _KpiMini(
                    label: 'Costo promedio',
                    value: promedio,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(iconVar, color: colorVar, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Variación: ${currency.format(variacion)} '
                  '(${variacionPct.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    color: colorVar,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiMini extends StatelessWidget {
  const _KpiMini({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
