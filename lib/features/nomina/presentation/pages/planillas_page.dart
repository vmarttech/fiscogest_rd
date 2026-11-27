import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/nomina/presentation/providers/nomina_providers.dart';

class PlanillasPage extends ConsumerWidget {
  const PlanillasPage({super.key});

  static const String routeName = 'nomina-planillas';
  static const String path = '/nomina/planillas';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(planillasListaProvider);

    return AppScaffold(
      title: 'Planillas',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nueva(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva planilla'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (lista) {
          if (lista.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 56,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sin planillas',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crea la planilla del mes o quincena con empleados activos.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _nueva(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Crear primera planilla'),
                    ),
                  ],
                ),
              ),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1250
                  ? 3
                  : constraints.maxWidth >= 760
                  ? 2
                  : 1;
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 10,
                  mainAxisExtent: columns == 1 ? 112 : 126,
                ),
                itemCount: lista.length,
                itemBuilder: (ctx, i) {
                  final p = lista[i];
                  final color = p.esPagada
                      ? AppColors.info
                      : p.esCerrada
                      ? AppColors.textSecondary
                      : AppColors.success;
                  final estado = p.esPagada
                      ? 'Pagada'
                      : p.esCerrada
                      ? 'Cerrada'
                      : 'Borrador';
                  return Material(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => context.push('/nomina/planillas/${p.id}'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.periodo,
                                    style: AppTypography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '$estado · Neto ${formatRd(p.totalNeto)}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatRd(p.totalBruto),
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Costo ${formatRd(p.totalCostoEmpleador)}',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static Future<void> _nueva(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final choice = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        Widget opt(String id, String title, String sub, IconData icon) {
          return ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(
                  ctx,
                ).colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Theme.of(ctx).colorScheme.primary),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(sub),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () => Navigator.pop(ctx, id),
          );
        }

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nueva planilla',
                    textAlign: TextAlign.center,
                    style: AppTypography.h4.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Elige el tipo de periodo. Se cargan empleados activos.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  opt(
                    'mensual',
                    'Mensual',
                    'Del 1 al último día del mes',
                    Icons.calendar_month_outlined,
                  ),
                  opt(
                    'quincena1',
                    '1.ª quincena',
                    'Días 1–15',
                    Icons.looks_one_outlined,
                  ),
                  opt(
                    'quincena2',
                    '2.ª quincena',
                    'Día 16 al fin de mes',
                    Icons.looks_two_outlined,
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (choice == null || !context.mounted) return;

    final y = now.year;
    final m = now.month;
    final mm = m.toString().padLeft(2, '0');
    late String periodo;
    late String tipo;
    late DateTime inicio;
    late DateTime fin;

    if (choice == 'mensual') {
      tipo = 'mensual';
      periodo = '$y-$mm';
      inicio = DateTime(y, m, 1);
      fin = DateTime(y, m + 1, 0);
    } else if (choice == 'quincena1') {
      tipo = 'quincena1';
      periodo = '$y-$mm-Q1';
      inicio = DateTime(y, m, 1);
      fin = DateTime(y, m, 15);
    } else {
      tipo = 'quincena2';
      periodo = '$y-$mm-Q2';
      inicio = DateTime(y, m, 16);
      fin = DateTime(y, m + 1, 0);
    }

    final empleados = await ref.read(empleadosListaProvider.future);
    final activos = empleados.where((e) => e.activo).toList();
    if (activos.isEmpty) {
      FiscoGestNotifications.show(
        const SnackBar(content: Text('No hay empleados activos')),
      );
      return;
    }

    try {
      final id = await ref
          .read(planillaRepositoryProvider)
          .crearDesdeEmpleados(
            periodo: periodo,
            tipoPeriodo: tipo,
            fechaInicio: inicio,
            fechaFin: fin,
            empleados: activos,
          );
      ref.invalidate(planillasListaProvider);
      if (context.mounted) {
        FiscoGestNotifications.show(
          SnackBar(content: Text('Planilla $periodo creada')),
        );
        await context.push('/nomina/planillas/$id');
      }
    } catch (e) {
      FiscoGestNotifications.show(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700),
      );
    }
  }
}
