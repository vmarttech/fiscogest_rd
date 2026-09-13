import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/convertir_cotizacion_provider.dart';
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

  String _etiquetaEstado(EstadoDocumento estado) => switch (estado) {
    EstadoDocumento.borrador => 'Borrador',
    EstadoDocumento.cotizado => 'Vigente',
    EstadoDocumento.enCredito => 'En aprobación',
    EstadoDocumento.aprobado => 'Aprobado',
    EstadoDocumento.anulado => 'Rechazado',
    EstadoDocumento.facturado => 'Convertida',
  };

  Color _colorEstado(EstadoDocumento estado) => switch (estado) {
    EstadoDocumento.borrador => AppColors.textSecondary,
    EstadoDocumento.cotizado => AppColors.primary,
    EstadoDocumento.enCredito => const Color(0xFFE65100),
    EstadoDocumento.aprobado => AppColors.success,
    EstadoDocumento.anulado => AppColors.error,
    EstadoDocumento.facturado => AppColors.success,
  };

  Color _colorFondoEstado(EstadoDocumento estado) => switch (estado) {
    EstadoDocumento.borrador => AppColors.textSecondary.withValues(alpha: 0.1),
    EstadoDocumento.cotizado => AppColors.primary.withValues(alpha: 0.1),
    EstadoDocumento.enCredito => const Color(0xFFE65100).withValues(alpha: 0.1),
    EstadoDocumento.aprobado => AppColors.success.withValues(alpha: 0.1),
    EstadoDocumento.anulado => AppColors.error.withValues(alpha: 0.1),
    EstadoDocumento.facturado => AppColors.success.withValues(alpha: 0.1),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ventasBorradorAsync = ref.watch(listaVentasBorradorProvider);

    return Padding(
      padding: AppSpacing.allM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            'Lista de cotizaciones y su estado',
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
                      'Error al cargar cotizaciones: $e',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              data: (List<VentaBorradorState> cotizaciones) {
                if (cotizaciones.isEmpty) {
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
                          'No hay cotizaciones registradas',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Las cotizaciones que registres aparecerán aquí',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: cotizaciones.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1),
                  itemBuilder: (_, int i) {
                    final VentaBorradorState c = cotizaciones[i];
                    return _TarjetaCotizacion(
                      cotizacion: c,
                      etiquetaEstado: _etiquetaEstado(c.estadoDocumento),
                      colorTextoEstado: _colorEstado(c.estadoDocumento),
                      colorFondoEstado: _colorFondoEstado(c.estadoDocumento),
                      fechaEmision: _formatearFecha(c.fecha),
                      fechaVencimiento: _formatearFecha(c.vencimiento),
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
    required this.cotizacion,
    required this.etiquetaEstado,
    required this.colorTextoEstado,
    required this.colorFondoEstado,
    required this.fechaEmision,
    required this.fechaVencimiento,
  });

  final VentaBorradorState cotizacion;
  final String etiquetaEstado;
  final Color colorTextoEstado;
  final Color colorFondoEstado;
  final String fechaEmision;
  final String fechaVencimiento;

  Future<void> _enviarAprobacion(WidgetRef ref, BuildContext context) async {
    if (cotizacion.id == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enviar a Aprobación'),
        content: Text('¿Enviar la Cotización N° ${cotizacion.numero} a aprobación de crédito?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Enviar')),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    try {
      final servicio = ref.read(cotizacionAprobacionProvider);
      await servicio.enviarAprobacion(cotizacion.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cotización ${cotizacion.numero} enviada a aprobación'), backgroundColor: AppColors.success),
        );
        ref.invalidate(listaVentasBorradorProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _convertirAVenta(WidgetRef ref, BuildContext context) async {
    if (cotizacion.id == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Convertir a Venta'),
        content: Text('¿Convertir la Cotización N° ${cotizacion.numero} en una Venta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Convertir')),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    try {
      final repo = ref.read(ventasRepositoryProvider);
      await repo.confirmarVentaBorrador(cotizacion.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cotización N° ${cotizacion.numero} convertida a Venta'), backgroundColor: AppColors.success),
        );
        ref.invalidate(listaVentasBorradorProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = cotizacion.estadoDocumento;
    final puedeEnviarAprobacion = estado == EstadoDocumento.cotizado && cotizacion.id != null;
    final puedeConvertir = estado == EstadoDocumento.aprobado && cotizacion.id != null;
    final convertida = estado == EstadoDocumento.facturado;

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
                      'Cotización N° ${cotizacion.numero}',
                      style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                      decoration: BoxDecoration(color: colorFondoEstado, borderRadius: BorderRadius.circular(4)),
                      child: Text(etiquetaEstado, style: AppTypography.labelSmall.copyWith(color: colorTextoEstado)),
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
              Text(
                'RD\$ ${cotizacion.montoTotal.toStringAsFixed(2)}',
                style: AppTypography.h4.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (puedeEnviarAprobacion)
                AppButton(text: 'Enviar a aprobación', onPressed: () => _enviarAprobacion(ref, context), height: 36)
              else if (puedeConvertir)
                AppButton(text: 'Convertir a Venta', onPressed: () => _convertirAVenta(ref, context), height: 36)
              else if (convertida)
                TextButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                  label: Text('Venta generada', style: AppTypography.labelSmall.copyWith(color: AppColors.success)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
