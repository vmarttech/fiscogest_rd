import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_section.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class ApartadosPage extends ConsumerStatefulWidget {
  const ApartadosPage({super.key});
  static const String routeName = 'apartados';
  @override
  ConsumerState<ApartadosPage> createState() => _ApartadosPageState();
}

class _ApartadosPageState extends ConsumerState<ApartadosPage> {
  @override
  Widget build(BuildContext context) {
    final listaApartados = ref.watch(listaApartadosProvider);
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
                  minHeight:
                      constraints.maxHeight -
                      AppLayout.pantallaPadding.vertical,
                ),
                child: listaApartados.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Padding(
                      padding: AppLayout.pantallaPadding,
                      child: Text(
                        'Error al cargar apartados: $error',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
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
                              DataColumn(
                                label: Text(
                                  'ID',
                                  style: AppTypography.bodyMedium,
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Producto',
                                  style: AppTypography.bodyMedium,
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Cantidad',
                                  style: AppTypography.bodyMedium,
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Cliente',
                                  style: AppTypography.bodyMedium,
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Fecha',
                                  style: AppTypography.bodyMedium,
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Estado',
                                  style: AppTypography.bodyMedium,
                                ),
                              ),
                            ],
                            rows: apartados.map((apt) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      '${apt['id']}',
                                      style: AppTypography.bodySmall,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${apt['productoNombre'] ?? '-'}',
                                      style: AppTypography.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${apt['cantidad']}',
                                      style: AppTypography.bodySmall,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${apt['clienteNombre'] ?? '-'}',
                                      style: AppTypography.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${apt['fechaApartado']}',
                                      style: AppTypography.bodySmall,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${apt['estado']}',
                                      style: AppTypography.bodySmall,
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
}
