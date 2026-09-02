import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/tarjeta_venta.dart';

class HistorialVentas extends ConsumerWidget {
  const HistorialVentas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listaVentas = ref.watch(listaVentasProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        return listaVentas.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Padding(
              padding: AppSpacing.allM,
              child: Text(
                'Error al cargar ventas: $error',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (ventas) {
            if (ventas.isEmpty) {
              return const Center(
                child: Padding(
                  padding: AppSpacing.allM,
                  child: Text(
                    'No hay ventas registradas',
                    style: AppTypography.bodyLarge,
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: AppSpacing.allM,
                  itemCount: ventas.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.s),
                  itemBuilder: (context, index) {
                    final venta = ventas[index];
                    return TarjetaVenta(
                      numero: venta.numero,
                      clienteNombre:
                          venta.nombreCliente ?? 'Cliente ${venta.clienteId}',
                      fecha: venta.fecha,
                      total: venta.total,
                      onTap: () {
                        ref
                            .read(ventaCargadaDesdeHistorialProvider.notifier)
                            .establecerVenta(venta);
                        ref
                            .read(ventasNavegacionProvider.notifier)
                            .cambiarVista(VistaActual.detalle);
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
