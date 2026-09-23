import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/convertir_cotizacion_provider.dart';

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
        EstadoDocumento.facturado => 'Facturada',
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
        EstadoDocumento.borrador =>
          AppColors.textSecondary.withValues(alpha: 0.12),
        EstadoDocumento.cotizado => AppColors.primary.withValues(alpha: 0.12),
        EstadoDocumento.enCredito =>
          const Color(0xFFE65100).withValues(alpha: 0.12),
        EstadoDocumento.aprobado => AppColors.success.withValues(alpha: 0.12),
        EstadoDocumento.anulado => AppColors.error.withValues(alpha: 0.12),
        EstadoDocumento.facturado => AppColors.success.withValues(alpha: 0.12),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ventasBorradorAsync = ref.watch(listaVentasBorradorProvider);
    final esPantallaPequena = MediaQuery.of(context).size.width < 600;
    final padding = esPantallaPequena ? 12.0 : 16.0;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cotizaciones',
                      style: AppTypography.h4.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: esPantallaPequena ? 16 : 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lista y estado de cotizaciones',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: esPantallaPequena ? 12 : 13,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: esPantallaPequena ? 40 : 44,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    esPantallaPequena ? 'Nueva' : 'Nueva Cotización',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: esPantallaPequena ? 13 : 14,
                    ),
                  ),
                  onPressed: () {
                    context.push('/ventas/cotizaciones/nueva');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: esPantallaPequena ? 12 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: esPantallaPequena ? 12 : 16),
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
                    const SizedBox(height: 12),
                    Text(
                      'Error al cargar cotizaciones: $e',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                        fontSize: esPantallaPequena ? 13 : 14,
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
                        Icon(
                          Icons.description_outlined,
                          size: esPantallaPequena ? 48 : 56,
                          color: AppColors.grey300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay cotizaciones registradas',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            fontSize: esPantallaPequena ? 14 : 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Las cotizaciones que registres aparecerán aquí',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: esPantallaPequena ? 12 : 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: cotizaciones.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(height: esPantallaPequena ? 8 : 10),
                  itemBuilder: (_, int i) {
                    final VentaBorradorState c = cotizaciones[i];
                    return _TarjetaCotizacion(
                      cotizacion: c,
                      etiquetaEstado: _etiquetaEstado(c.estadoDocumento),
                      colorTextoEstado: _colorEstado(c.estadoDocumento),
                      colorFondoEstado: _colorFondoEstado(c.estadoDocumento),
                      fechaEmision: _formatearFecha(c.fecha),
                      fechaVencimiento: _formatearFecha(c.vencimiento),
                      esPantallaPequena: esPantallaPequena,
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
    required this.esPantallaPequena,
  });

  final VentaBorradorState cotizacion;
  final String etiquetaEstado;
  final Color colorTextoEstado;
  final Color colorFondoEstado;
  final String fechaEmision;
  final String fechaVencimiento;
  final bool esPantallaPequena;

  Future<void> _enviarAprobacion(WidgetRef ref, BuildContext context) async {
    if (cotizacion.id == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enviar a Aprobación'),
        content: Text(
          '¿Enviar la Cotización N° ${cotizacion.numero} a aprobación de crédito?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    try {
      final servicio = ref.read(cotizacionAprobacionProvider);
      await servicio.enviarAprobacion(cotizacion.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cotización ${cotizacion.numero} enviada a aprobación',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Solo navega a Caja. No factura aquí.
  Future<void> _irACaja(WidgetRef ref, BuildContext context) async {
    if (cotizacion.id == null) return;

    final esCredito = cotizacion.esCredito ||
        cotizacion.tipoPago.toLowerCase().contains('credito') ||
        cotizacion.tipoPago.toLowerCase().contains('crédito') ||
        cotizacion.numero.startsWith('CR-');

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ir a Caja'),
        content: Text(
          '¿Cobrar la Cotización N° ${cotizacion.numero} en Caja?\n\n'
          'Allí se generará el número de factura fiscal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Ir a Caja'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    context.push(
      '/ventas/cobro/operacion',
      extra: <String, dynamic>{
        'ventaId': cotizacion.id,
        'montoTotal': cotizacion.montoTotal,
        'esCredito': esCredito,
        'numeroCotizacion': cotizacion.numero,
        'nombreCliente': cotizacion.clienteNombre,
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = cotizacion.estadoDocumento;
    final puedeEnviarAprobacion =
        estado == EstadoDocumento.cotizado && cotizacion.id != null;
    final puedeIrACaja =
        estado == EstadoDocumento.aprobado && cotizacion.id != null;
    final convertida = estado == EstadoDocumento.facturado;
    final tamanoCuerpo = esPantallaPequena ? 13.0 : 14.0;
    final tamanoTotal = esPantallaPequena ? 16.0 : 18.0;
    final tamanoEtiqueta = esPantallaPequena ? 11.0 : 12.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: EdgeInsets.all(esPantallaPequena ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'N° ${cotizacion.numero}',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: esPantallaPequena ? 14 : 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorFondoEstado,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  etiquetaEstado,
                  style: AppTypography.labelSmall.copyWith(
                    color: colorTextoEstado,
                    fontWeight: FontWeight.w600,
                    fontSize: tamanoEtiqueta,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emitida: $fechaEmision',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: tamanoEtiqueta,
                      ),
                    ),
                    Text(
                      'Vence: $fechaVencimiento',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: tamanoEtiqueta,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'RD\$ ${cotizacion.montoTotal.toStringAsFixed(2)}',
                style: AppTypography.h4.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: tamanoTotal,
                ),
              ),
            ],
          ),
          if (puedeEnviarAprobacion || puedeIrACaja || convertida) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            if (puedeEnviarAprobacion)
              SizedBox(
                width: double.infinity,
                height: esPantallaPequena ? 40 : 44,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: Text(
                    'Enviar a aprobación',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: tamanoCuerpo,
                    ),
                  ),
                  onPressed: () => _enviarAprobacion(ref, context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              )
            else if (puedeIrACaja)
              SizedBox(
                width: double.infinity,
                height: esPantallaPequena ? 40 : 44,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.point_of_sale, size: 18),
                  label: Text(
                    'Ir a Caja / Cobrar',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: tamanoCuerpo,
                    ),
                  ),
                  onPressed: () => _irACaja(ref, context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              )
            else if (convertida)
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Venta generada',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: tamanoEtiqueta,
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
