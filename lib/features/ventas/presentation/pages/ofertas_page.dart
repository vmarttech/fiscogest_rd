import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/descuentos_ofertas_providers.dart';

class OfertasPage extends ConsumerStatefulWidget {
  const OfertasPage({super.key});
  static const String routeName = 'ofertas';

  @override
  ConsumerState<OfertasPage> createState() => _OfertasPageState();
}

class _OfertasPageState extends ConsumerState<OfertasPage> {
  @override
  Widget build(BuildContext context) {
    final ofertasAsync = ref.watch(ofertasActivosProvider);

    return AppScaffold(
      title: 'Ofertas',
      body: SingleChildScrollView(
        padding: AppLayout.pantallaPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración y Listado de Ofertas',
              style: AppTypography.h4,
            ),
            AppLayout.vM,
            ofertasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error al cargar ofertas: $error',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                ),
              ),
              data: (ofertas) {
                if (ofertas.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay ofertas activas en este momento',
                      style: AppTypography.bodyMedium,
                    ),
                  );
                }
                return Column(
                  children: ofertas.map((oferta) {
                    return Padding(
                      padding: AppSpacing.vS,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              oferta.nombre,
                              style: AppTypography.labelMedium,
                            ),
                            Text(
                              'Producto ID: ${oferta.productoId}',
                              style: AppTypography.bodySmall,
                            ),
                            Text(
                              'Cantidad mínima: ${oferta.cantidadMinima}',
                              style: AppTypography.bodySmall,
                            ),
                            Text(
                              'Precio oferta: ${oferta.precioOferta}',
                              style: AppTypography.bodySmall,
                            ),
                            Text(
                              'Vigencia: ${oferta.vigenciaDesde.day}/${oferta.vigenciaDesde.month}/${oferta.vigenciaDesde.year} - ${oferta.vigenciaHasta.day}/${oferta.vigenciaHasta.month}/${oferta.vigenciaHasta.year}',
                              style: AppTypography.bodySmall,
                            ),
                            Text(
                              'Estado: ${oferta.estado}',
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
