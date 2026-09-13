import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_cargada_desde_historial_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_borrador_servicio_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/convertir_cotizacion_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';
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

  String _formatearFecha(DateTime fecha) => 'Hoy · ${DateFormat.Hm().format(fecha)}';
  String _formatearMonto(double valor) => 'RD\$${NumberFormat('#,##0.00', 'es_DO').format(valor)}';

  String _etiquetaEstado(EstadoDocumento estado) => switch (estado) {
    EstadoDocumento.cotizado => 'Vigente',
    EstadoDocumento.enCredito => 'En aprobación',
    EstadoDocumento.aprobado => 'Aprobado',
    EstadoDocumento.anulado => 'Rechazado',
    EstadoDocumento.facturado => 'Convertida',
    _ => 'Borrador',
  };

  Color _colorEstado(EstadoDocumento estado) => switch (estado) {
    EstadoDocumento.cotizado => AppColors.primary,
    EstadoDocumento.enCredito => const Color(0xFFE65100),
    EstadoDocumento.aprobado => AppColors.success,
    EstadoDocumento.anulado => AppColors.error,
    EstadoDocumento.facturado => AppColors.success,
    _ => AppColors.textSecondary,
  };

  Future<void> _imprimir(BuildContext context, WidgetRef ref) async {
    try {
      final servicio = ref.read(ventaBorradorServicioProvider);
      final resultado = await servicio.generarImpresion(venta);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resultado), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al imprimir: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _exportarPDF(BuildContext context, WidgetRef ref) async {
    try {
      final servicio = ref.read(ventaBorradorServicioProvider);
      final ruta = await servicio.exportarPDF(venta);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Archivo generado: $ruta'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al generar archivo: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _enviarPorCorreo(BuildContext context, WidgetRef ref) async {
    try {
      final servicio = ref.read(ventaBorradorServicioProvider);
      await servicio.enviarPorCorreo(venta, '');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _enviarAprobacion(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enviar a Aprobación'),
        content: Text('¿Enviar la Cotización N° ${venta.numero} a aprobación de crédito?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Enviar')),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    try {
      final servicio = ref.read(cotizacionAprobacionProvider);
      await servicio.enviarAprobacion(venta.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cotización ${venta.numero} enviada a aprobación'), backgroundColor: AppColors.success),
        );
        ref.invalidate(listaVentasBorradorProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _aprobarCredito(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aprobar Crédito'),
        content: Text('¿Aprobar la cotización N° ${venta.numero}? Pasará a Venta.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.success), onPressed: () => Navigator.pop(context, true), child: const Text('Aprobar', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    try {
      final servicio = ref.read(cotizacionAprobacionProvider);
      await servicio.aprobarCredito(venta.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Cotización ${venta.numero} aprobada. Ya puede ser convertida a Venta.'), backgroundColor: AppColors.success, duration: const Duration(seconds: 4)),
        );
        ref.invalidate(listaVentasBorradorProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _rechazarCredito(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rechazar Crédito'),
        content: Text('¿Rechazar la cotización N° ${venta.numero}? Quedará anulada.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), onPressed: () => Navigator.pop(context, true), child: const Text('Rechazar', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    try {
      final servicio = ref.read(cotizacionAprobacionProvider);
      await servicio.rechazarCredito(venta.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cotización ${venta.numero} rechazada y anulada'), backgroundColor: AppColors.success),
        );
        ref.invalidate(listaVentasBorradorProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _convertirCotizacion(BuildContext context, WidgetRef ref) async {
    if (!venta.numero.startsWith('C')) return;
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Convertir Cotización'),
        content: Text('¿Desea convertir la cotización ${venta.numero} en una venta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    try {
      final casoUso = ref.read(convertirCotizacionAVentaProvider);
      final resultado = await casoUso.call(venta.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cotización convertida: ${resultado.numero}'), backgroundColor: AppColors.success),
        );
        ref.read(ventaCargadaDesdeHistorialProvider.notifier).limpiarVenta();
        ref.read(ventasNavegacionProvider.notifier).cambiarVista(VistaActual.inicio);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al convertir: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = venta.estadoDocumento;
    final puedeEnviarAprobacion = estado == EstadoDocumento.cotizado && venta.id != null;
    final puedeAprobarRechazar = estado == EstadoDocumento.enCredito && venta.id != null;
    final puedeConvertir = estado == EstadoDocumento.aprobado && venta.id != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
                onPressed: () {
                  ref.read(ventaCargadaDesdeHistorialProvider.notifier).limpiarVenta();
                  ref.read(ventasNavegacionProvider.notifier).cambiarVista(VistaActual.inicio);
                },
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('Cotización #${venta.numero}', style: AppTypography.h4.copyWith(fontSize: 18)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_formatearFecha(venta.fecha), style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: _colorEstado(estado).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(_etiquetaEstado(estado), style: TextStyle(fontSize: 12, color: _colorEstado(estado), fontWeight: FontWeight.w500)),
                        ),
                      ],
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
                  Expanded(flex: 5, child: Text('${linea.cantidad} × ${linea.nombreProducto}', style: AppTypography.bodyMedium)),
                  Expanded(flex: 2, child: Text(_formatearMonto(linea.precioUnitario), textAlign: TextAlign.right, style: AppTypography.bodySmall)),
                  Expanded(flex: 2, child: Text(_formatearMonto(linea.subtotalLinea ?? linea.subtotal), textAlign: TextAlign.right, style: AppTypography.labelMedium)),
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
          _FilaResumen('TOTAL', _formatearMonto(venta.total), esResaltado: true),
          const SizedBox(height: 24),
          const Text('Pago', style: AppTypography.labelLarge),
          const SizedBox(height: 8),
          Row(children: [const Icon(Icons.payment, size: 18), const SizedBox(width: 8), Text(venta.tipoPago, style: AppTypography.bodyMedium)]),
          const SizedBox(height: 16),
          const Text('Cliente', style: AppTypography.labelLarge),
          const SizedBox(height: 8),
          Row(children: [const Icon(Icons.person_outline, size: 18), const SizedBox(width: 8), Text(venta.nombreCliente ?? 'Consumidor final', style: AppTypography.bodyMedium)]),
          const SizedBox(height: 32),
          const Text('Acciones', style: AppTypography.labelLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(onPressed: () => _imprimir(context, ref), icon: const Icon(Icons.print, size: 18), label: const Text('Imprimir')),
              TextButton.icon(onPressed: () => _exportarPDF(context, ref), icon: const Icon(Icons.picture_as_pdf, size: 18), label: const Text('PDF')),
              TextButton.icon(onPressed: () => _enviarPorCorreo(context, ref), icon: const Icon(Icons.email_outlined, size: 18), label: const Text('Enviar')),
              if (puedeEnviarAprobacion)
                AppButton(text: 'ENVIAR A APROBACIÓN', onPressed: () => _enviarAprobacion(context, ref), icon: Icons.send, height: 40),
              if (puedeAprobarRechazar) ...[
                AppButton(text: 'APROBAR', onPressed: () => _aprobarCredito(context, ref), icon: Icons.check_circle, height: 40),
                OutlinedButton.icon(onPressed: () => _rechazarCredito(context, ref), icon: const Icon(Icons.cancel), label: const Text('Rechazar'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10))),
              ],
              if (puedeConvertir)
                TextButton.icon(onPressed: () => _convertirCotizacion(context, ref), icon: const Icon(Icons.swap_horiz, size: 18), label: const Text('Convertir a Venta')),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vaya a Facturación → Nota de Crédito / Devolución.'), backgroundColor: AppColors.success));
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
          Text(etiqueta, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: esResaltado ? FontWeight.bold : FontWeight.normal)),
          Text(valor, style: AppTypography.bodyMedium.copyWith(fontWeight: esResaltado ? FontWeight.bold : FontWeight.normal, fontSize: esResaltado ? 16 : 14, color: esResaltado ? AppColors.primary : null)),
        ],
      ),
    );
  }
}
