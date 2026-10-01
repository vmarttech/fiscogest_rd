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
import 'package:fiscogest_rd/features/comercial/presentation/providers/compra/historial_costos_providers.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/historial_costo.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';

class HistorialCostosPage extends ConsumerWidget {
  const HistorialCostosPage({super.key, required this.productoId});

  static const String routeName = 'historial-costos';
  final int productoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(historialCostosProvider(productoId));

    return AppScaffold(
      title: 'Historial de Costos',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
          onPressed: () => ref.invalidate(historialCostosProvider(productoId)),
        ),
      ],
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Error: $e', style: AppTypography.error)),
        data: (HistorialCostoResumen resumen) {
          if (resumen.items.isEmpty) {
            return Center(
              child: Padding(
                padding: AppSpacing.allL,
                child: Text(
                  'No hay compras registradas para este producto.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMediumSecondary,
                ),
              ),
            );
          }
          return ListView(
            padding: AppLayout.pantallaPadding,
            children: [
              Text(resumen.nombreProducto, style: AppTypography.h4Bold),
              AppLayout.vM,
              _ResumenCostos(
                ultimo: formatRd(resumen.ultimoCosto),
                promedio: formatRd(resumen.costoPromedio),
                variacion: resumen.variacion,
                variacionPct: resumen.variacionPorcentaje,
              ),
              AppLayout.vL,
              const AppSection(title: 'Historial', children: []),
              AppLayout.vS,
              ...resumen.items.map((item) {
                return Padding(
                  padding: AppSpacing.bS,
                  child: AppCard(
                    onTap: () =>
                        context.go('/compras/detalle/${item.compraId}'),
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: AppSpacing.hM,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: const Icon(
                          Icons.attach_money,
                          color: AppColors.primary,
                          size: AppSizes.iconMd,
                        ),
                      ),
                      title: Text(
                        formatRd(item.costoAdquisicion),
                        style: AppTypography.bodyMediumBold,
                      ),
                      subtitle: Text(
                        '${item.proveedorNombre}\n'
                        '${DateFormat('dd/MM/yyyy').format(item.fecha)}'
                        '${item.ncf.isNotEmpty ? ' · ${item.ncf}' : ''}',
                        style: AppTypography.bodySmall,
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        'x${item.cantidad.toStringAsFixed(0)}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
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
  });

  final String ultimo;
  final String promedio;
  final double variacion;
  final double variacionPct;

  @override
  Widget build(BuildContext context) {
    final colorVar = variacion > 0
        ? AppColors.error
        : variacion < 0
        ? AppColors.success
        : AppColors.textSecondary;
    final iconVar = variacion > 0
        ? Icons.trending_up
        : variacion < 0
        ? Icons.trending_down
        : Icons.trending_flat;

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _KpiMini(
                  label: 'Último costo',
                  value: ultimo,
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _KpiMini(
                  label: 'Costo promedio',
                  value: promedio,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.l),
          Row(
            children: [
              Icon(iconVar, color: colorVar, size: AppSizes.iconMd),
              AppLayout.hS,
              Text(
                'Variación: ${formatRd(variacion)} '
                '(${variacionPct.toStringAsFixed(1)}%)',
                style: AppTypography.bodyMediumSemiBold.copyWith(
                  color: colorVar,
                ),
              ),
            ],
          ),
        ],
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
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        AppLayout.vXs,
        Text(value, style: AppTypography.h4Bold.copyWith(color: color)),
      ],
    );
  }
}
