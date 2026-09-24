import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
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
import 'package:go_router/go_router.dart';
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

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year} · ${DateFormat.Hm().format(fecha)}';
  }

  String _formatearMonto(double valor) =>
      'RD\$${NumberFormat('#,##0.00', 'es_DO').format(valor)}';

  String _etiquetaEstado(EstadoDocumento estado) => switch (estado) {
        EstadoDocumento.cotizado => 'Vigente',
        EstadoDocumento.enCredito => 'En aprobación',
        EstadoDocumento.aprobado => 'Aprobado',
        EstadoDocumento.anulado => 'Rechazado',
        EstadoDocumento.facturado => 'Facturada',
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

  Color _colorFondoEstado(EstadoDocumento estado) => switch (estado) {
        EstadoDocumento.cotizado => AppColors.primary.withValues(alpha: 0.12),
        EstadoDocumento.enCredito =>
          const Color(0xFFE65100).withValues(alpha: 0.12),
        EstadoDocumento.aprobado => AppColors.success.withValues(alpha: 0.12),
        EstadoDocumento.anulado => AppColors.error.withValues(alpha: 0.12),
        EstadoDocumento.facturado => AppColors.success.withValues(alpha: 0.12),
        _ => AppColors.textSecondary.withValues(alpha: 0.12),
      };

  bool get _esCredito {
    if (venta.esCredito) return true;
    final pago = venta.formaPago.toLowerCase();
    if (pago.contains('credito') || pago.contains('crédito')) return true;
    return venta.numeroCotizacion.startsWith('CR-');
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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al imprimir: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar archivo: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _enviarAprobacion(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enviar a Aprobación'),
        content: Text(
          '¿Enviar la Cotización N° ${venta.numero} a aprobación de crédito?',
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
      await servicio.enviarAprobacion(venta.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cotización ${venta.numero} enviada a aprobación'),
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

  Future<void> _aprobarCredito(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Aprobar Crédito'),
        content: Text(
          '¿Aprobar la cotización N° ${venta.numero}?\nPasará a estado Aprobado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    try {
      final servicio = ref.read(cotizacionAprobacionProvider);
      await servicio.aprobarCredito(venta.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cotización ${venta.numero} aprobada. Ya puede ir a Caja.',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
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

  Future<void> _rechazarCredito(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rechazar Crédito'),
        content: Text(
          '¿Rechazar la cotización N° ${venta.numero}? Quedará anulada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    try {
      final servicio = ref.read(cotizacionAprobacionProvider);
      await servicio.rechazarCredito(venta.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cotización ${venta.numero} rechazada y anulada'),
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

  /// Solo navega a Caja. La factura se genera exclusivamente allí.
  Future<void> _irACaja(BuildContext context, WidgetRef ref) async {
    if (venta.id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ir a Caja'),
        content: Text(
          '¿Cobrar la cotización N° ${venta.numero} en Caja?\n\n'
          'Allí se generará el número de factura fiscal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ir a Caja'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    ref.read(ventaCargadaDesdeHistorialProvider.notifier).limpiarVenta();
    ref.read(ventasNavegacionProvider.notifier).cambiarVista(VistaActual.inicio);

    if (!context.mounted) return;
    context.push(
      '/ventas/cobro/operacion',
      extra: <String, dynamic>{
        'ventaId': venta.id,
        'montoTotal': venta.montoTotal,
        'esCredito': _esCredito,
        'numeroCotizacion': venta.numeroCotizacion,
        'nombreCliente': venta.nombreCliente,
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = venta.estadoDocumento;
    final puedeEnviarAprobacion =
        estado == EstadoDocumento.cotizado && venta.id != null;
    // Aprobar/rechazar crédito SOLO en módulo Créditos (no ventas).
    const puedeAprobarRechazar = false;
    final puedeIrACaja =
        estado == EstadoDocumento.aprobado && venta.id != null;
    final esPantallaPequena = MediaQuery.of(context).size.width < 600;
    final padding = esPantallaPequena ? 12.0 : 16.0;
    final tamanoCuerpo = esPantallaPequena ? 13.0 : 14.0;
    final tamanoTotal = esPantallaPequena ? 20.0 : 22.0;
    final tamanoEtiqueta = esPantallaPequena ? 11.0 : 12.0;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(padding, padding, padding, 8),
            physics: const AlwaysScrollableScrollPhysics(),
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
                            'N° ${venta.numero}',
                            style: AppTypography.h4.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: esPantallaPequena ? 16 : 18,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatearFecha(venta.fecha),
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: tamanoEtiqueta,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _colorFondoEstado(estado),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _etiquetaEstado(estado),
                                  style: TextStyle(
                                    fontSize: tamanoEtiqueta,
                                    color: _colorEstado(estado),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                SizedBox(height: esPantallaPequena ? 16 : 20),
                _seccionCard(
                  esPantallaPequena: esPantallaPequena,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cliente',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: tamanoEtiqueta,
                              ),
                            ),
                            Text(
                              venta.nombreCliente ?? 'Consumidor final',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: tamanoCuerpo,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (venta.tipoPago.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            venta.tipoPago,
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: tamanoEtiqueta,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: esPantallaPequena ? 12 : 14),
                Text(
                  'Productos',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: esPantallaPequena ? 13 : 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _seccionCard(
                  esPantallaPequena: esPantallaPequena,
                  child: Column(
                    children: [
                      ...venta.detalles.asMap().entries.map((entrada) {
                        final linea = entrada.value;
                        final esUltimo =
                            entrada.key == venta.detalles.length - 1;
                        return Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: esPantallaPequena ? 8 : 10,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          linea.nombreProducto ?? 'Producto',
                                          style:
                                              AppTypography.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w500,
                                            fontSize: tamanoCuerpo,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Cant: ${linea.cantidad}  ×  ${_formatearMonto(linea.precioUnitario)}',
                                          style:
                                              AppTypography.bodySmall.copyWith(
                                            fontSize: tamanoEtiqueta,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatearMonto(
                                      linea.subtotalLinea ?? linea.subtotal,
                                    ),
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: tamanoCuerpo,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!esUltimo)
                              const Divider(height: 1, indent: 0, endIndent: 0),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                SizedBox(height: esPantallaPequena ? 12 : 14),
                _seccionCard(
                  esPantallaPequena: esPantallaPequena,
                  child: Column(
                    children: [
                      _FilaResumen(
                        'Subtotal',
                        _formatearMonto(venta.subtotal),
                        fontSize: tamanoCuerpo,
                      ),
                      _FilaResumen(
                        'ITBIS (18%)',
                        _formatearMonto(venta.itbis),
                        fontSize: tamanoCuerpo,
                      ),
                      if (venta.montoDescuento > 0)
                        _FilaResumen(
                          'Descuento',
                          '- ${_formatearMonto(venta.montoDescuento)}',
                          fontSize: tamanoCuerpo,
                          colorValor: AppColors.error,
                        ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL',
                            style: AppTypography.h4.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: esPantallaPequena ? 15 : 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _formatearMonto(venta.total),
                            style: AppTypography.h3.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: tamanoTotal,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: esPantallaPequena ? 12 : 14),
                Text(
                  'Documentos',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: esPantallaPequena ? 13 : 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chipAccion(
                      icon: Icons.print_outlined,
                      label: 'Imprimir',
                      onTap: () => _imprimir(context, ref),
                      esPantallaPequena: esPantallaPequena,
                    ),
                    _chipAccion(
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'PDF',
                      onTap: () => _exportarPDF(context, ref),
                      esPantallaPequena: esPantallaPequena,
                    ),
                    _chipAccion(
                      icon: Icons.email_outlined,
                      label: 'Enviar',
                      onTap: () => _enviarPorCorreo(context, ref),
                      esPantallaPequena: esPantallaPequena,
                    ),
                    _chipAccion(
                      icon: Icons.receipt_long_outlined,
                      label: 'Devolución',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Vaya a Facturación → Nota de Crédito / Devolución.',
                            ),
                            backgroundColor: AppColors.info,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      esPantallaPequena: esPantallaPequena,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        if (puedeEnviarAprobacion || puedeAprobarRechazar || puedeIrACaja)
          _barraAccionesEstado(
            context: context,
            ref: ref,
            puedeEnviarAprobacion: puedeEnviarAprobacion,
            puedeAprobarRechazar: puedeAprobarRechazar,
            puedeIrACaja: puedeIrACaja,
            esPantallaPequena: esPantallaPequena,
          ),
      ],
    );
  }

  Widget _seccionCard({
    required bool esPantallaPequena,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(esPantallaPequena ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _chipAccion({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool esPantallaPequena,
  }) {
    return Material(
      color: AppColors.grey50,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: esPantallaPequena ? 10 : 12,
            vertical: esPantallaPequena ? 8 : 9,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: esPantallaPequena ? 12 : 13,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barraAccionesEstado({
    required BuildContext context,
    required WidgetRef ref,
    required bool puedeEnviarAprobacion,
    required bool puedeAprobarRechazar,
    required bool puedeIrACaja,
    required bool esPantallaPequena,
  }) {
    final altura = esPantallaPequena ? 48.0 : 52.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        esPantallaPequena ? 12 : 16,
        10,
        esPantallaPequena ? 12 : 16,
        esPantallaPequena ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: puedeAprobarRechazar
            ? Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: altura,
                      child: OutlinedButton.icon(
                        onPressed: () => _rechazarCredito(context, ref),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: Text(
                          'Rechazar',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: esPantallaPequena ? 13 : 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: altura,
                      child: ElevatedButton.icon(
                        onPressed: () => _aprobarCredito(context, ref),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(
                          'APROBAR CRÉDITO',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: esPantallaPequena ? 13 : 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : SizedBox(
                width: double.infinity,
                height: altura,
                child: ElevatedButton.icon(
                  onPressed: puedeEnviarAprobacion
                      ? () => _enviarAprobacion(context, ref)
                      : puedeIrACaja
                          ? () => _irACaja(context, ref)
                          : null,
                  icon: Icon(
                    puedeEnviarAprobacion
                        ? Icons.send_outlined
                        : Icons.point_of_sale,
                    size: 18,
                  ),
                  label: Text(
                    puedeEnviarAprobacion
                        ? 'ENVIAR A APROBACIÓN'
                        : 'IR A CAJA / COBRAR',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: esPantallaPequena ? 13 : 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        puedeIrACaja ? AppColors.success : AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  const _FilaResumen(
    this.etiqueta,
    this.valor, {
    this.fontSize = 14,
    this.colorValor,
  });

  final String etiqueta;
  final String valor;
  final double fontSize;
  final Color? colorValor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            etiqueta,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: fontSize,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            valor,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: colorValor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
