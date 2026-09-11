import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_cargada_desde_historial_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_borrador_servicio_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/convertir_cotizacion_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/vistas/vista_inicio_vacia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class VistaDetalle extends ConsumerWidget {
  const VistaDetalle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Venta? ventaCargada = ref.watch(ventaCargadaDesdeHistorialProvider);
    if (ventaCargada != null) {
      return _MostrarDetalleVenta(venta: ventaCargada);
    }
    return const VistaInicioVacia();
  }
}

class _MostrarDetalleVenta extends ConsumerWidget {
  const _MostrarDetalleVenta({required this.venta});
  final Venta venta;

  String _formatearFecha(DateTime fecha) =>
      'Hoy · ${DateFormat.Hm().format(fecha)}';

  String _formatearMonto(double valor) =>
      'RD\$${NumberFormat('#,##0.00', 'es_DO').format(valor)}';

  Future<void> _imprimir(BuildContext context, WidgetRef ref) async {
    try {
      final servicio = ref.read(ventaBorradorServicioProvider);
      final resultado = await servicio.generarImpresion(venta);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al imprimir: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _exportarPDF(BuildContext context, WidgetRef ref) async {
    try {
      final servicio = ref.read(ventaBorradorServicioProvider);
      final ruta = await servicio.exportarPDF(venta);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archivo generado: $ruta'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar archivo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _enviarPorCorreo(BuildContext context, WidgetRef ref) async {
    try {
      final servicio = ref.read(ventaBorradorServicioProvider);
      await servicio.enviarPorCorreo(venta, '');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _convertirCotizacion(BuildContext context, WidgetRef ref) async {
    if (!venta.numero.startsWith('C')) return;

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Convertir Cotización'),
        content: Text(
          '¿Desea convertir la cotización ${venta.numero} en una venta?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    try {
      final casoUso = ref.read(convertirCotizacionAVentaProvider);
      final resultado = await casoUso.call(venta.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cotización convertida: ${resultado.numero}'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(ventaCargadaDesdeHistorialProvider.notifier).limpiarVenta();
        ref
            .read(ventasNavegacionProvider.notifier)
            .cambiarVista(VistaActual.inicio);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al convertir: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  ref
                      .read(ventaCargadaDesdeHistorialProvider.notifier)
                      .limpiarVenta();
                  ref
                      .read(ventasNavegacionProvider.notifier)
                      .cambiarVista(VistaActual.inicio);
                },
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Venta #${venta.numero}',
                      style: AppTypography.h4.copyWith(fontSize: 18),
                    ),
                    Text(
                      _formatearFecha(venta.fecha),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const Divider(height: 32),
          const Text('Productos', style: AppTypography.labelLarge),
          const SizedBox(height: 12),
          ...venta.detalles.map((item) {
            final linea = item;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      '${linea.cantidad} × ${linea.nombreProducto}',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatearMonto(linea.precioUnitario),
                      textAlign: TextAlign.right,
                      style: AppTypography.bodySmall,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatearMonto(linea.subtotalLinea ?? linea.subtotal),
                      textAlign: TextAlign.right,
                      style: AppTypography.labelMedium,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          _FilaResumen('Subtotal', _formatearMonto(venta.subtotal)),
          _FilaResumen('ITBIS', _formatearMonto(venta.itbis)),
          const SizedBox(height: 4),
          const Divider(),
          _FilaResumen(
            'TOTAL',
            _formatearMonto(venta.total),
            esResaltado: true,
          ),
          const SizedBox(height: 24),
          const Text('Pago', style: AppTypography.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.payment, size: 18),
              const SizedBox(width: 8),
              Text(venta.tipoPago, style: AppTypography.bodyMedium),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Cliente', style: AppTypography.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18),
              const SizedBox(width: 8),
              Text(
                venta.nombreCliente ?? 'Consumidor final',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Acciones', style: AppTypography.labelLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => _imprimir(context, ref),
                icon: const Icon(Icons.print, size: 18),
                label: const Text('Imprimir'),
              ),
              TextButton.icon(
                onPressed: () => _exportarPDF(context, ref),
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('PDF'),
              ),
              TextButton.icon(
                onPressed: () => _enviarPorCorreo(context, ref),
                icon: const Icon(Icons.email_outlined, size: 18),
                label: const Text('Enviar'),
              ),
              if (venta.numero.startsWith('C'))
                TextButton.icon(
                  onPressed: () => _convertirCotizacion(context, ref),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Convertir a Venta'),
                ),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Vaya a Facturación → Nota de Crédito / Devolución.',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text('Devolución'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  const _FilaResumen(this.etiqueta, this.valor, {this.esResaltado = false});
  final String etiqueta;
  final String valor;
  final bool esResaltado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            etiqueta,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: esResaltado ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            valor,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: esResaltado ? FontWeight.bold : FontWeight.normal,
              fontSize: esResaltado ? 16 : 14,
              color: esResaltado ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
