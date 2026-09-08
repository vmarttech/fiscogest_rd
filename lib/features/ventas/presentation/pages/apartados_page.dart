import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_section.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/features/apartados/presentation/providers/apartado_provider.dart';

class ApartadosPage extends ConsumerStatefulWidget {
  const ApartadosPage({super.key});
  static const String routeName = 'apartados';
  @override
  ConsumerState<ApartadosPage> createState() => _ApartadosPageState();
}

class _ApartadosPageState extends ConsumerState<ApartadosPage> {
  @override
  Widget build(BuildContext context) {
    final listaApartadosAsync = ref.watch(apartadoNotifierProvider);
    final apartadoNotifier = ref.read(apartadoNotifierProvider.notifier);

    return AppScaffold(
      title: 'Productos Apartados',
      body: SafeArea(
        bottom: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppLayout.pantallaPadding,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppLayout.pantallaPadding.vertical,
                ),
                child: listaApartadosAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Padding(
                      padding: AppLayout.pantallaPadding,
                      child: Text(
                        'Error al cargar apartados: $error',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  data: (apartados) {
                    if (apartados.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: AppLayout.pantallaPadding,
                          child: Text(
                            'No hay productos apartados',
                            style: AppTypography.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return AppSection(
                      title: 'Apartados (${apartados.length})',
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: DataTable(
                            columnSpacing: AppSpacing.l,
                            columns: const [
                              DataColumn(label: Text('ID', style: AppTypography.bodyMedium)),
                              DataColumn(label: Text('Número', style: AppTypography.bodyMedium)),
                              DataColumn(label: Text('Cliente', style: AppTypography.bodyMedium)),
                              DataColumn(label: Text('Total', style: AppTypography.bodyMedium)),
                              DataColumn(label: Text('Abonado', style: AppTypography.bodyMedium)),
                              DataColumn(label: Text('Fecha', style: AppTypography.bodyMedium)),
                              DataColumn(label: Text('Estado', style: AppTypography.bodyMedium)),
                              DataColumn(label: Text('Acciones', style: AppTypography.bodyMedium)),
                            ],
                            rows: apartados.map((apt) {
                              final aptId = apt.id ?? 0;
                              final estado = apt.estado;
                              final esActivo = estado == 'Activo';
                              return DataRow(
                                cells: [
                                  DataCell(Text('$aptId', style: AppTypography.bodySmall)),
                                  DataCell(Text(apt.numero, style: AppTypography.bodySmall)),
                                  DataCell(Text('${apt.clienteId}', style: AppTypography.bodySmall)),
                                  DataCell(Text('RD\$ ${apt.montoTotal.toStringAsFixed(2)}', style: AppTypography.bodySmall)),
                                  DataCell(Text('RD\$ ${apt.montoAbonado.toStringAsFixed(2)}', style: AppTypography.bodySmall)),
                                  DataCell(Text(apt.fechaApartado.toString().substring(0, 10), style: AppTypography.bodySmall)),
                                  DataCell(Text(estado, style: AppTypography.bodySmall)),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.payment, size: 18, color: Colors.blue),
                                          tooltip: 'Registrar abono',
                                          onPressed: esActivo ? () => _mostrarDialogoAbono(context, aptId, apartadoNotifier) : null,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.cancel, size: 18, color: Colors.redAccent),
                                          tooltip: 'Cancelar apartado',
                                          onPressed: esActivo ? () => _mostrarDialogoCancelar(context, aptId, apartadoNotifier) : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _mostrarDialogoAbono(BuildContext context, int apartadoId, ApartadoNotifier notifier) {
    final ctrlMonto = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Abono'),
        content: TextField(
          controller: ctrlMonto,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monto del abono',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final monto = double.tryParse(ctrlMonto.text);
              if (monto == null || monto <= 0) return;
              Navigator.pop(ctx);
              await notifier.registrarAbono(apartadoId, monto);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Abono registrado correctamente')),
                );
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCancelar(BuildContext context, int apartadoId, ApartadoNotifier notifier) {
    final ctrlMotivo = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Apartado'),
        content: TextField(
          controller: ctrlMotivo,
          decoration: const InputDecoration(
            labelText: 'Motivo de cancelación',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Volver')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final motivo = ctrlMotivo.text.trim();
              if (motivo.isEmpty) return;
              Navigator.pop(ctx);
              await notifier.cancelarApartado(apartadoId, motivo);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Apartado cancelado — inventario liberado')),
                );
              }
            },
            child: const Text('Cancelar Apartado'),
          ),
        ],
      ),
    );
  }
}
