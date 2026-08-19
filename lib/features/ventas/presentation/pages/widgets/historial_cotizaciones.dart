import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class HistorialCotizaciones extends ConsumerWidget {
  const HistorialCotizaciones({super.key});

  String _formatearFecha(dynamic valor) {
    if (valor == null) return 'Sin fecha';
    if (valor is String) return valor;
    if (valor is DateTime) {
      return '${valor.day.toString().padLeft(2, '0')}/${valor.month.toString().padLeft(2, '0')}/${valor.year}';
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

  bool _valorComoBooleano(Map<String, dynamic> mapa, String clave) {
    final v = mapa[clave] ?? mapa[clave.replaceAllMapped(RegExp(r'_([a-z])'), (m) => m.group(1)!.toUpperCase())];
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v == 1;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cotizacionesAsync = ref.watch(listaCotizacionesProvider);

    return Padding(
      padding: AppSpacing.allM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Cotizaciones', style: AppTypography.h4),
          const SizedBox(height: AppSpacing.xs),
          Text('Lista de cotizaciones emitidas y su estado', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.m),
          Expanded(
            child: cotizacionesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: AppSpacing.m),
                    Text('Error al cargar cotizaciones: $e', style: AppTypography.bodyMedium.copyWith(color: AppColors.error), textAlign: TextAlign.center),
                  ],
                ),
              ),
              data: (cotizaciones) {
                if (cotizaciones.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: AppSpacing.m),
                        Text('No hay cotizaciones registradas', style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: AppSpacing.xs),
                        Text('Las cotizaciones que registres aparecerán aquí', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: cotizaciones.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1),
                  itemBuilder: (_, i) {
                    final c = cotizaciones[i];
                    final numero = _valorComoString(c, 'numero', 'S/N');
                    final fechaEmision = _formatearFecha(c['fechaEmision'] ?? c['fecha_emision']);
                    final fechaVencimiento = _formatearFecha(c['fechaVencimiento'] ?? c['fecha_vencimiento']);
                    final total = _valorComoDouble(c, 'total');
                    final convertida = _valorComoBooleano(c, 'convertidaAVenta') || _valorComoBooleano(c, 'convertida_a_venta');
                    final cotizacionId = c['id'] as int?;

                    return _TarjetaCotizacion(
                      numero: numero,
                      fechaEmision: fechaEmision,
                      fechaVencimiento: fechaVencimiento,
                      total: total,
                      convertida: convertida,
                      cotizacionId: cotizacionId,
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

class _TarjetaCotizacion extends ConsumerWidget {
  const _TarjetaCotizacion({
    required this.numero,
    required this.fechaEmision,
    required this.fechaVencimiento,
    required this.total,
    required this.convertida,
    required this.cotizacionId,
  });

  final String numero;
  final String fechaEmision;
  final String fechaVencimiento;
  final double total;
  final bool convertida;
  final int? cotizacionId;

  Future<void> _convertirAVenta(WidgetRef ref, BuildContext context) async {
    if (cotizacionId == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Convertir a Venta'),
        content: Text('¿Convertir la Cotización N° $numero en una Venta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Convertir', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirmar != true || !ref.context.mounted) return;

    try {
      final repo = ref.read(ventasRepositoryProvider);
      await repo.convertirCotizacionAVenta(cotizacionId!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Cotización N° $numero convertida a Venta'), backgroundColor: Colors.green),
        );
        ref.invalidate(listaCotizacionesProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: AppSpacing.vS,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Cotización N° $numero', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: AppSpacing.s),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                      decoration: BoxDecoration(
                        color: convertida ? Colors.green.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        convertida ? 'Convertida' : 'Vigente',
                        style: AppTypography.labelSmall.copyWith(
                          color: convertida ? Colors.green.shade700 : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('Emitida: $fechaEmision', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                Text('Vence: $fechaVencimiento', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('RD\$ ${total.toStringAsFixed(2)}', style: AppTypography.h4.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.xs),
              if (!convertida && cotizacionId != null)
                AppButton(
                  text: 'Convertir a Venta',
                  onPressed: () => _convertirAVenta(ref, context),
                ),
              if (convertida)
                TextButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  label: Text('Venta generada', style: AppTypography.labelSmall.copyWith(color: Colors.green.shade700)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
