import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/apartado.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class HistorialApartados extends ConsumerWidget {
  const HistorialApartados({super.key});

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
    final apartadosAsync = ref.watch(listaApartadosProvider);
    return Padding(
      padding: AppSpacing.allM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Apartados', style: AppTypography.h4),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Reservas de productos con control de pagos',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Expanded(
            child: apartadosAsync.when(
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
                      'Error al cargar apartados: $e',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              data: (List<dynamic> apartados) {
                if (apartados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Color(0x409E9E9E),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        Text(
                          'No hay apartados registrados',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Los apartados que registres aparecerán aquí',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: apartados.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, thickness: 1),
                  itemBuilder: (_, int i) {
                    final Apartado a = apartados[i] as Apartado;
                    final String numero = a.numero;
                    final String fechaApartado = _formatearFecha(
                      a.fechaApartado,
                    );
                    final String fechaLimite = _formatearFecha(
                      a.fechaLimitePago,
                    );
                    final double montoTotal = a.montoTotal;
                    final double montoAbonado = a.montoAbonado;
                    final double saldoPendiente = a.saldoPendiente;
                    final String estado = a.estado;
                    return _TarjetaApartado(
                      numero: numero,
                      fechaApartado: fechaApartado,
                      fechaLimite: fechaLimite,
                      montoTotal: montoTotal,
                      montoAbonado: montoAbonado,
                      saldoPendiente: saldoPendiente,
                      estado: estado,
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

class _TarjetaApartado extends StatelessWidget {
  const _TarjetaApartado({
    required this.numero,
    required this.fechaApartado,
    required this.fechaLimite,
    required this.montoTotal,
    required this.montoAbonado,
    required this.saldoPendiente,
    required this.estado,
  });

  final String numero;
  final String fechaApartado;
  final String fechaLimite;
  final double montoTotal;
  final double montoAbonado;
  final double saldoPendiente;
  final String estado;

  Color _colorEstado() {
    final String e = estado.toUpperCase();
    if (e == 'PAGADO' || e == 'COMPLETADO') return Colors.green;
    if (e == 'VENCIDO') return AppColors.error;
    if (e == 'CANCELADO') return Colors.grey;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final double porcentajePagado = montoTotal > 0
        ? (montoAbonado / montoTotal).clamp(0.0, 1.0)
        : 0.0;
    return Padding(
      padding: AppSpacing.vS,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Apartado N° $numero',
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
                  color: _colorEstado().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  estado,
                  style: AppTypography.labelSmall.copyWith(
                    color: _colorEstado(),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apartado: $fechaApartado',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Límite pago: $fechaLimite',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'RD\$ ${montoAbonado.toStringAsFixed(2)} / RD\$ ${montoTotal.toStringAsFixed(2)}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          'Saldo: RD\$ ${saldoPendiente.toStringAsFixed(2)}',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: saldoPendiente > 0
                                ? AppColors.error
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: porcentajePagado,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _colorEstado(),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
