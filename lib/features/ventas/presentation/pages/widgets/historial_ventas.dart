import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_cargada_desde_historial_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';

class HistorialVentas extends ConsumerWidget {
  const HistorialVentas({super.key});

  String formatearFecha(DateTime fecha) => DateFormat('dd/MM · HH:mm').format(fecha);
  String formatearMonto(double valor) => NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2).format(valor);

  String obtenerEtiquetaTipo(Venta v) {
    if (v.numero.startsWith('C')) return 'Cotización';
    if (v.numero.startsWith('A')) return 'Apartado';
    return 'Venta';
  }

  Color obtenerColorTipo(Venta v) {
    if (v.numero.startsWith('C')) return AppColors.info;
    if (v.numero.startsWith('A')) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listaVentas = ref.watch(listaVentasProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🕘 Historial de Ventas', style: AppTypography.h4),
              TextButton.icon(
                onPressed: () => ref.read(ventasNavegacionProvider.notifier).cambiarVista(VistaActual.inicio),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Volver'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: listaVentas.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e', style: AppTypography.bodyMedium.copyWith(color: AppColors.error), textAlign: TextAlign.center))),
            data: (ventas) {
              if (ventas.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.grey400), SizedBox(height: 16), Text('No hay ventas registradas', style: AppTypography.labelLarge, textAlign: TextAlign.center), SizedBox(height: 8), Text('Las ventas aparecerán aquí al confirmarlas', style: AppTypography.bodyMedium, textAlign: TextAlign.center)])));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: ventas.length,
                itemBuilder: (ctx, i) {
                  final v = ventas[i];
                  final color = obtenerColorTipo(v);
                  final etiqueta = obtenerEtiquetaTipo(v);
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: InkWell(
                      onTap: () {
                        ref.read(ventaCargadaDesdeHistorialProvider.notifier).establecerVenta(v);
                        ref.read(ventasNavegacionProvider.notifier).cambiarVista(VistaActual.detalle);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(v.numero, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(formatearFecha(v.fecha), style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary))])),
                          Expanded(flex: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Text(etiqueta, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)))),
                          Expanded(flex: 3, child: Text(formatearMonto(v.total), textAlign: TextAlign.right, style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold))),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, size: 18, color: AppColors.grey400),
                        ]),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
