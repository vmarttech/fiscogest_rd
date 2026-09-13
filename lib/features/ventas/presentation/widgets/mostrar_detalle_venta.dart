import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';

class MostrarDetalleVenta extends ConsumerWidget {
  const MostrarDetalleVenta({super.key, required this.venta});
  final Venta venta;

  String _formatearFecha(DateTime fecha) {
    return DateFormat.yMd().add_Hm().format(fecha);
  }

  String _formatearMonto(double valor) {
    return 'RD\$${NumberFormat('#,##0.00', 'es_DO').format(valor)}';
  }

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
    final correo = venta.nombreCliente != null ? 'correo@ejemplo.com' : '';
    try {
      final servicio = ref.read(ventaBorradorServicioProvider);
      await servicio.enviarPorCorreo(venta, correo);
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
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
      final casoUso = ref.read(confirmarVentaBorradorUseCaseProvider);
      final resultado = await casoUso.call(venta.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cotización convertida: ${resultado.numero}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
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
      padding: AppSpacing.allM,
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
                      'Transacción Nº ${venta.numero}',
                      style: AppTypography.h4,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      _formatearFecha(venta.fecha),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const Divider(),
          const SizedBox(height: AppSpacing.m),
          const Text(
            'Datos del Cliente y Pago',
            style: AppTypography.labelLarge,
          ),
          const SizedBox(height: AppSpacing.s),
          FilaDetalle('Nº Transacción', venta.numero),
          FilaDetalle('Cliente ID', '${venta.clienteId}'),
          if (venta.nombreCliente != null)
            FilaDetalle('Nombre', venta.nombreCliente!),
          FilaDetalle('Fecha y Hora', _formatearFecha(venta.fecha)),
          FilaDetalle('Forma de Pago', venta.tipoPago),
          FilaDetalle('A crédito', venta.esCredito ? 'Sí' : 'No'),
          FilaDetalle('Atendido por', 'Usuario ${venta.usuarioId}'),
          const SizedBox(height: AppSpacing.l),
          const Text('Detalle de Artículos', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.s),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  color: AppColors.grey100,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Descripción',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Cant',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Precio',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Impuesto',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Subtotal',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                ...venta.detalles.map(
                  (linea) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            linea.nombreProducto as String,
                            style: AppTypography.bodySmall,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${linea.cantidad}',
                            textAlign: TextAlign.right,
                            style: AppTypography.bodySmall,
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
                            '${linea.tasaImpuesto}%',
                            textAlign: TextAlign.right,
                            style: AppTypography.bodySmall,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _formatearMonto(linea.subtotalLinea as double),
                            textAlign: TextAlign.right,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 260,
              child: Column(
                children: [
                  FilaDetalle('Subtotal', _formatearMonto(venta.subtotal)),
                  FilaDetalle('ITBIS', _formatearMonto(venta.itbis)),
                  const Divider(),
                  FilaDetalle(
                    'TOTAL',
                    _formatearMonto(venta.total),
                    esResaltado: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          const Text('Acciones', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              OutlinedButton.icon(
                onPressed: () => _imprimir(context, ref),
                icon: const Icon(Icons.print, size: 18),
                label: const Text('Imprimir'),
              ),
              OutlinedButton.icon(
                onPressed: () => _exportarPDF(context, ref),
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('Exportar PDF'),
              ),
              OutlinedButton.icon(
                onPressed: () => _enviarPorCorreo(context, ref),
                icon: const Icon(Icons.email_outlined, size: 18),
                label: const Text('Enviar al Cliente'),
              ),
              if (venta.numero.startsWith('C'))
                OutlinedButton.icon(
                  onPressed: () => _convertirCotizacion(context, ref),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Convertir a Venta'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Transacción ${venta.numero} copiada como referencia. Vaya a Facturación → Nota de Crédito / Devolución.',
                      ),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text('Usar para Devolución / NC'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Número ${venta.numero} copiado al portapapeles',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copiar Nº Transacción'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          ElevatedButton.icon(
            onPressed: () {
              ref
                  .read(ventaCargadaDesdeHistorialProvider.notifier)
                  .limpiarVenta();
              ref
                  .read(ventasNavegacionProvider.notifier)
                  .cambiarVista(VistaActual.inicio);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver al historial'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class FilaDetalle extends StatelessWidget {
  const FilaDetalle(
    this.etiqueta,
    this.valor, {
    super.key,
    this.esResaltado = false,
  });
  final String etiqueta, valor;
  final bool esResaltado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            etiqueta,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            valor,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: esResaltado ? FontWeight.bold : FontWeight.normal,
              color: esResaltado ? AppColors.primary : null,
              fontSize: esResaltado ? 16 : null,
            ),
          ),
        ],
      ),
    );
  }
}
