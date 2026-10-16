import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:fiscogest_rd/features/facturacion/presentation/pdf/comprobante_pdf.dart';
import 'package:fiscogest_rd/features/e_cf/presentation/providers/ecfe_providers.dart';

class MostrarDetalleVenta extends ConsumerWidget {
  const MostrarDetalleVenta({super.key, required this.venta});
  final Venta venta;

  String _formatearFecha(DateTime fecha) {
    return DateFormat.yMd().add_Hm().format(fecha);
  }

  String _formatearMonto(double valor) => formatRd(valor);

  Future<void> _imprimir(BuildContext context, WidgetRef ref) async {
    try {
      Venta v = venta;
      if (v.id != null) {
        final full =
            await ref.read(ventasRepositoryProvider).obtenerVentaPorId(v.id!);
        if (full != null) v = full;
      }
      if (v.detalles.isEmpty) {
        if (context.mounted) {
          FiscoGestNotifications.show(
            const SnackBar(
              content: Text(
                'Sin líneas de producto. No se puede reimprimir el comprobante.',
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }
      final emp = ref.read(configuracionControllerProvider).valueOrNull;
      final codigo = v.id == null
          ? null
          : await ref.read(ecfeRepositoryProvider).codigoSeguridadPorVenta(v.id!);
      final ambiente =
          (await ref.read(ecfeRepositoryProvider).obtenerConfig()).ambiente;
      await ComprobantePdf.imprimirFactura(
        v,
        empresa: emp,
        codigoSeguridad: codigo,
        ambienteDgii: ambiente,
      );
    } catch (e) {
      if (context.mounted) {
        FiscoGestNotifications.show(
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
      Venta v = venta;
      if (v.id != null) {
        final full =
            await ref.read(ventasRepositoryProvider).obtenerVentaPorId(v.id!);
        if (full != null) v = full;
      }
      final emp = ref.read(configuracionControllerProvider).valueOrNull;
      final codigo = v.id == null
          ? null
          : await ref.read(ecfeRepositoryProvider).codigoSeguridadPorVenta(v.id!);
      final ambiente =
          (await ref.read(ecfeRepositoryProvider).obtenerConfig()).ambiente;
      await ComprobantePdf.imprimirFactura(
        v,
        compartir: true,
        empresa: emp,
        codigoSeguridad: codigo,
        ambienteDgii: ambiente,
      );
    } catch (e) {
      if (context.mounted) {
        FiscoGestNotifications.show(
          SnackBar(
            content: Text('Error al exportar PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

    Future<void> _enviarPorCorreo(BuildContext context, WidgetRef ref) async {
    final correoCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enviar al cliente'),
        content: TextField(
          controller: correoCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo del cliente',
            hintText: 'cliente@correo.com',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final correo = correoCtrl.text.trim();
    if (correo.isEmpty || !correo.contains('@')) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Indique un correo válido'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      Venta v = venta;
      if (v.id != null) {
        final full = await ref.read(ventasRepositoryProvider).obtenerVentaPorId(v.id!);
        if (full != null) v = full;
      }
      // 1) Intentar servicio de negocio
      try {
        final servicio = ref.read(ventaBorradorServicioProvider);
        await servicio.enviarPorCorreo(v, correo);
      } catch (_) {
        // 2) Fallback: PDF compartible (correo / WhatsApp del sistema)
        final emp = ref.read(configuracionControllerProvider).valueOrNull;
        final codigo = v.id == null
            ? null
            : await ref.read(ecfeRepositoryProvider).codigoSeguridadPorVenta(v.id!);
        final ambiente =
            (await ref.read(ecfeRepositoryProvider).obtenerConfig()).ambiente;
        await ComprobantePdf.imprimirFactura(
          v,
          compartir: true,
          empresa: emp,
          codigoSeguridad: codigo,
          ambienteDgii: ambiente,
        );
      }
      if (context.mounted) {
        FiscoGestNotifications.show(
          SnackBar(
            content: Text('Comprobante listo para enviar a $correo'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        FiscoGestNotifications.show(
          SnackBar(
            content: Text('No se pudo enviar: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktop = AppBreakpoints.isDesktop(context);
    final simple = ref
            .watch(configuracionControllerProvider)
            .valueOrNull
            ?.modoSimplificado ==
        true;
    final ncf = (venta.numeroFactura ?? '').trim();

    Widget card({required Widget child, EdgeInsetsGeometry? padding}) {
      return Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      );
    }

    Widget sectionTitle(String s) => Text(
          s,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: 0.1,
          ),
        );

    Widget kv(String k, String v, {bool bold = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                k,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            Flexible(
              child: Text(
                v,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: bold ? 14 : 13.5,
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final acciones = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        _AccionChip(
          icon: Icons.print_outlined,
          label: 'Imprimir',
          color: const Color(0xFF0F766E),
          onTap: () => _imprimir(context, ref),
        ),
        _AccionChip(
          icon: Icons.picture_as_pdf_outlined,
          label: 'PDF',
          color: const Color(0xFF7C3AED),
          onTap: () => _exportarPDF(context, ref),
        ),
        _AccionChip(
          icon: Icons.share_outlined,
          label: 'Enviar',
          color: AppColors.info,
          onTap: () => _enviarPorCorreo(context, ref),
        ),
        _AccionChip(
          icon: Icons.receipt_long_outlined,
          label: 'Devolución / NC',
          color: AppColors.warning,
          onTap: () {
            final n = venta.numero;
            final ncfLocal = (venta.numeroFactura ?? '').trim();
            Clipboard.setData(
              ClipboardData(text: ncfLocal.isNotEmpty ? ncfLocal : n),
            );
            context.push('/ventas/devoluciones');
            FiscoGestNotifications.show(
              SnackBar(
                content: Text(
                  'Referencia $n copiada. Registre la devolución / NC.',
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        _AccionChip(
          icon: Icons.copy_rounded,
          label: 'Copiar Nº',
          color: const Color(0xFF64748B),
          onTap: () async {
            final n = venta.numero;
            final ncfLocal = (venta.numeroFactura ?? '').trim();
            final text = ncfLocal.isNotEmpty ? '$n · NCF $ncfLocal' : n;
            await Clipboard.setData(ClipboardData(text: text));
            if (context.mounted) {
              FiscoGestNotifications.show(
                SnackBar(
                  content: Text('Copiado: $text'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ],
    );

    final datos = card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sectionTitle('DATOS DEL CLIENTE Y PAGO'),
          const SizedBox(height: 10),
          kv('Nº Transacción', venta.numero),
          if ((venta.nombreCliente ?? '').trim().isNotEmpty)
            kv('Cliente', venta.nombreCliente!.trim()),
          kv('Fecha y hora', _formatearFecha(venta.fecha)),
          kv('Forma de pago', venta.tipoPago),
          kv('A crédito', venta.esCredito ? 'Sí' : 'No'),
          if (ncf.isNotEmpty) kv('NCF', ncf, bold: true),
          kv('Atendido por', 'Usuario ${venta.usuarioId}'),
        ],
      ),
    );

    final articulos = card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sectionTitle('DETALLE DE ARTÍCULOS'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'Descripción',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Cant',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Precio',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Subtotal',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ...venta.detalles.map((linea) {
            final nombre = (linea.nombreProducto ?? 'Ítem').toString();
            double sub = 0;
            try {
              sub = (linea.subtotalLinea as num).toDouble();
            } catch (_) {
              try {
                sub = (linea.subtotal as num).toDouble();
              } catch (_) {}
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${linea.cantidad}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatearMonto(linea.precioUnitario),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatearMonto(sub),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );

    Widget filaResumen(String k, String v, {bool total = false}) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: total ? 2 : 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              k,
              style: TextStyle(
                fontSize: total ? 14 : 13,
                fontWeight: total ? FontWeight.w900 : FontWeight.w600,
                color: total ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
            Text(
              v,
              style: TextStyle(
                fontSize: total ? 20 : 14,
                fontWeight: FontWeight.w900,
                color: total ? const Color(0xFF0F766E) : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      );
    }

    final totales = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF0F766E).withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sectionTitle('RESUMEN'),
          const SizedBox(height: 12),
          filaResumen('Subtotal', _formatearMonto(venta.subtotal)),
          if (!simple) filaResumen('ITBIS', _formatearMonto(venta.itbis)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFF99F6E4)),
          ),
          filaResumen('TOTAL', _formatearMonto(venta.total), total: true),
        ],
      ),
    );

    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: desktop ? 1100 : 720),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              desktop ? 28 : 16,
              desktop ? 20 : 12,
              desktop ? 28 : 16,
              32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera: título izq. + acciones der.
                if (desktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        tooltip: 'Volver al historial',
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF0F172A),
                        ),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/ventas/historial');
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transacción Nº ${venta.numero}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatearFecha(venta.fecha),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            if (ncf.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'NCF: $ncf',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(child: acciones),
                    ],
                  )
                else ...[
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Volver',
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/ventas/historial');
                          }
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Transacción Nº ${venta.numero}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatearFecha(venta.fecha),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (ncf.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'NCF: $ncf',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  acciones,
                ],
                const SizedBox(height: 18),
                if (desktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Columna principal: datos + líneas
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            datos,
                            const SizedBox(height: 14),
                            articulos,
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Columna lateral: solo resumen (ancho fijo visual)
                      Expanded(
                        flex: 3,
                        child: totales,
                      ),
                    ],
                  )
                else ...[
                  datos,
                  const SizedBox(height: 12),
                  totales,
                  const SizedBox(height: 12),
                  articulos,
                ],
              ],
            ),
          ),
        ),
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

class _AccionChip extends StatelessWidget {
  const _AccionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
