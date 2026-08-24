import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';

class HistorialVentas extends ConsumerWidget {
  const HistorialVentas({super.key});

  String _formatearFecha(DateTime fecha) {
    return DateFormat.yMd('es_DO').add_Hm().format(fecha);
  }

  String _formatearMonto(double valor) {
    return NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$ ').format(valor);
  }

  String _obtenerNombreCliente(Venta venta) {
    if (venta.nombreCliente != null && venta.nombreCliente!.isNotEmpty) {
      return venta.nombreCliente!;
    }
    return 'Cliente ${venta.clienteId}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listaVentas = ref.watch(listaVentasProvider);

    return listaVentas.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: AppSpacing.allM,
          child: Text(
            'Error al cargar ventas: $error',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
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

        return ListView.separated(
          padding: AppSpacing.allM,
          itemCount: ventas.length,
          separatorBuilder: (context, index) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            final venta = ventas[index];
            return Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              child: InkWell(
                onTap: () {
                  ref.read(ventaCargadaDesdeHistorialProvider.notifier).establecerVenta(venta);
                  ref.read(ventasNavegacionProvider.notifier).cambiarVista(VistaActual.detalle);
                },
                child: Padding(
                  padding: AppSpacing.allM,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            venta.numero,
                            style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatearFecha(venta.fecha),
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _obtenerNombreCliente(venta),
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            venta.tipoPago,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                          ),
                          Text(
                            _formatearMonto(venta.total),
                            style: AppTypography.h4.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
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
  }
}
