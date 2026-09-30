import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class CarritoVenta extends ConsumerWidget {
  const CarritoVenta({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadoLocal = ref.watch(registrarVentaProvider);
    return AppCard(
      padding: AppLayout.pantallaPadding,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Carrito',
                style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${estadoLocal.detalles.length} productos',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
          const Divider(),
          if (estadoLocal.detalles.isEmpty)
            const Padding(
              padding: AppSpacing.allL,
              child: Center(child: Text('Busque y agregue productos arriba')),
            )
          else
            ...estadoLocal.detalles.map((detalleRaw) {
              final DetalleVenta detalle = detalleRaw;
              return Padding(
                padding: AppSpacing.vS,
                child: ListTile(
                  title: Text(
                    detalle.nombreProducto ?? '',
                    style: AppTypography.bodyMedium,
                  ),
                  subtitle: Text(
                    'Cant: ${detalle.cantidad} • ${formatRd((detalle.subtotalLinea ?? detalle.subtotal))}',
                    style: AppTypography.bodySmall,
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    onPressed: () => ref
                        .read(registrarVentaProvider.notifier)
                        .quitarProducto(
                          estadoLocal.detalles.indexOf(detalleRaw),
                        ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
