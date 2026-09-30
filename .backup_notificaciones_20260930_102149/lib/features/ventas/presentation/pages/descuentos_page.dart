import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/descuentos_ofertas_providers.dart';

class DescuentosPage extends ConsumerStatefulWidget {
  const DescuentosPage({super.key});
  static const String routeName = 'descuentos';

  @override
  ConsumerState<DescuentosPage> createState() => _DescuentosPageState();
}

class _DescuentosPageState extends ConsumerState<DescuentosPage> {
  @override
  Widget build(BuildContext context) {
    final descuentosAsync = ref.watch(descuentosActivosProvider);

    return AppScaffold(
      title: 'Descuentos',
      body: SingleChildScrollView(
        padding: AppLayout.pantallaPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración y Listado de Descuentos',
              style: AppTypography.h4,
            ),
            AppLayout.vM,
            descuentosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error al cargar descuentos: $error',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                ),
              ),
              data: (descuentos) {
                if (descuentos.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay descuentos activos en este momento',
                      style: AppTypography.bodyMedium,
                    ),
                  );
                }
                return Column(
                  children: descuentos.map((descuento) {
                    return Padding(
                      padding: AppSpacing.vS,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              descuento.motivo,
                              style: AppTypography.labelMedium,
                            ),
                            Text(
                              'Tipo: ${descuento.tipo.name}',
                              style: AppTypography.bodySmall,
                            ),
                            Text(
                              'Valor: ${descuento.valor}${descuento.esPorcentaje ? '%' : ''}',
                              style: AppTypography.bodySmall,
                            ),
                            Text(
                              'Fecha: ${descuento.fechaRegistro.day}/${descuento.fechaRegistro.month}/${descuento.fechaRegistro.year}',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
