import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class HistorialVentas extends ConsumerWidget {
  const HistorialVentas({super.key});

  String _formatearFecha(dynamic valor) {
    if (valor == null) return 'Sin fecha';
    if (valor is String) return valor;
    if (valor is DateTime) {
      return '${valor.day.toString().padLeft(2, '0')}/${valor.month.toString().padLeft(2, '0')}/${valor.year} ${valor.hour.toString().padLeft(2, '0')}:${valor.minute.toString().padLeft(2, '0')}';
    }
    return valor.toString();
  }

  String _valorComoString(Map<String, dynamic> mapa, String clave, [String defecto = '']) {
    final v = mapa[clave];
    return v != null ? v.toString() : defecto;
  }

  double _valorComoDouble(Map<String, dynamic> mapa, String clave) {
    final v = mapa[clave];
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ventasAsync = ref.watch(listaVentasProvider);

    return Padding(
      padding: AppSpacing.allM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Historial de Ventas', style: AppTypography.h4),
          const SizedBox(height: AppSpacing.xs),
          Text('Consulta todas las ventas registradas en el sistema', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.m),
          Expanded(
            child: ventasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: AppSpacing.m),
                    Text('Error al cargar el historial: $e', style: AppTypography.bodyMedium.copyWith(color: AppColors.error), textAlign: TextAlign.center),
                  ],
                ),
              ),
              data: (ventas) {
                if (ventas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: AppSpacing.m),
                        Text('No hay ventas registradas', style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: AppSpacing.xs),
                        Text('Las ventas que registres aparecerán aquí', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: ventas.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1),
                  itemBuilder: (_, i) {
                    final venta = ventas[i];
                    return _TarjetaVenta(
                      venta: venta,
                      formatearFecha: _formatearFecha,
                      valorComoString: _valorComoString,
                      valorComoDouble: _valorComoDouble,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaVenta extends StatelessWidget {
  const _TarjetaVenta({
    required this.venta,
    required this.formatearFecha,
    required this.valorComoString,
    required this.valorComoDouble,
  });
  final Map<String, dynamic> venta;
  final String Function(dynamic) formatearFecha;
  final String Function(Map<String, dynamic>, String, [String]) valorComoString;
  final double Function(Map<String, dynamic>, String) valorComoDouble;

  @override
  Widget build(BuildContext context) {
    final numero = valorComoString(venta, 'numero', 'S/N');
    final tipoPago = valorComoString(venta, 'tipo_pago', 'tipoPago');
    final fecha = formatearFecha(venta['fecha'] ?? venta['created_at']);
    final total = valorComoDouble(venta, 'total');
    final itbis = valorComoDouble(venta, 'itbis');

    return Padding(
      padding: AppSpacing.vS,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Venta N° $numero', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: AppSpacing.s),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(tipoPago, style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('Fecha: $fecha', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('RD\$ ${total.toStringAsFixed(2)}', style: AppTypography.h4.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.xs),
              Text('ITBIS: RD\$ ${itbis.toStringAsFixed(2)}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
