import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/nueva_venta_borrador_page.dart';

class HistorialVentasBorrador extends ConsumerWidget {
  const HistorialVentasBorrador({super.key});

  String _formatearFecha(dynamic valor) {
    if (valor == null) return 'Sin fecha';
    if (valor is String) return valor;
    if (valor is DateTime) {
      return '${valor.day.toString().padLeft(2, '0')}/${valor.month.toString().padLeft(2, '0')}/${valor.year}';
    }
    return valor.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ventasBorradorAsync = ref.watch(listaVentasBorradorProvider);
    return Padding(
      padding: AppSpacing.allM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cotizaciones', style: AppTypography.h4),
              AppButton(
                text: 'Nueva Cotización',
                onPressed: () {
                  context.goNamed(NuevaVentaBorradorPage.routeName);
                },
                icon: Icons.add,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Lista de ventas borrador emitidas y su estado',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Expanded(
            child: ventasBorradorAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace? _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      'Error al cargar ventas borrador: $e',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              data: (List<VentaBorradorState> ventasBorrador) {
                if (ventasBorrador.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: Color(0x409E9E9E),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        Text(
                          'No hay ventas borrador registradas',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Las ventas borrador que registres aparecerán aquí',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: ventasBorrador.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, thickness: 1),
                  itemBuilder: (_, int i) {
                    final VentaBorradorState c = ventasBorrador[i];
                    final String numero = c.numero;
                    final String fechaEmision = _formatearFecha(c.fecha);
                    final String fechaVencimiento = _formatearFecha(
                      c.vencimiento,
                    );
                    final double total = c.montoTotal;
                    const bool convertida = false;
                    const int? ventaBorradorId = null;
                    return _TarjetaCotizacion(
                      numero: numero,
                      fechaEmision: fechaEmision,
                      fechaVencimiento: fechaVencimiento,
                      total: total,
                      convertida: convertida,
                      ventaBorradorId: ventaBorradorId,
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
    required this.ventaBorradorId,
  });

  final String numero;
  final String fechaEmision;
  final String fechaVencimiento;
  final double total;
  final bool convertida;
  final int? ventaBorradorId;

  Future<void> _convertirAVenta(WidgetRef ref, BuildContext context) async {
    if (ventaBorradorId == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext _) => AlertDialog(
        title: const Text('Convertir a Venta'),
        content: Text('¿Convertir la Cotización N° $numero en una Venta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Convertir',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    try {
      final repo = ref.read(ventasRepositoryProvider);
      await repo.confirmarVentaBorrador(ventaBorradorId!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cotización N° $numero convertida a Venta'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(listaVentasBorradorProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
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
                    Text(
                      'Cotización N° $numero',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: convertida
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        convertida ? 'Convertida' : 'Vigente',
                        style: AppTypography.labelSmall.copyWith(
                          color: convertida
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Emitida: $fechaEmision',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Vence: $fechaVencimiento',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'RD\$ ${total.toStringAsFixed(2)}',
                style: AppTypography.h4.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (!convertida && ventaBorradorId != null)
                AppButton(
                  text: 'Convertir a Venta',
                  onPressed: () => _convertirAVenta(ref, context),
                ),
              if (convertida)
                TextButton.icon(
                  onPressed: null,
                  icon: const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.success,
                  ),
                  label: Text(
                    'Venta generada',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
