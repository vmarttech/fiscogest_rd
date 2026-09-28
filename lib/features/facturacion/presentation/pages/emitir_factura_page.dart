import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/facturacion/presentation/providers/facturacion_providers.dart';
import 'package:fiscogest_rd/features/facturacion/presentation/pdf/comprobante_pdf.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_completo_providers.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_completo.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';

class EmitirFacturaPage extends ConsumerStatefulWidget {
  const EmitirFacturaPage({super.key});

  @override
  ConsumerState<EmitirFacturaPage> createState() => _EmitirFacturaPageState();
}

class _EmitirFacturaPageState extends ConsumerState<EmitirFacturaPage> {
  final _fmt = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$');
  Venta? _seleccion;
  String _tipoNcf = 'B02';
  String _rncCliente = '';
  bool _emitiendo = false;


  Future<void> _seleccionar(Venta d) async {
    setState(() {
      _seleccion = d;
      _tipoNcf = 'B02';
      _rncCliente = '';
    });
    try {
      final repo = ref.read(clienteCompletoRepositoryProvider);
      final lista = await repo.obtenerClientes();
      ClienteCompleto? cli;
      for (final c in lista) {
        if (c.id == d.clienteId) {
          cli = c;
          break;
        }
      }
      final rnc = (cli?.rncCedula ?? '').trim();
      final esRnc = (rnc.length == 9 || rnc.length == 11) && RegExp(r'^\d+$').hasMatch(rnc);
      if (mounted) {
        setState(() {
          _tipoNcf = esRnc ? 'B01' : 'B02';
        });
      }
    } catch (_) {
      // sin datos de cliente → B02
    }
  }

  Future<void> _emitir() async {
    final v = _seleccion;
    if (v == null || v.id == null) return;
    setState(() => _emitiendo = true);
    try {
      final ncf = await ref.read(emitirFacturaServiceProvider).emitir(
            ventaId: v.id!,
            tipoNcf: _tipoNcf,
            rncCliente: _rncCliente,
          );
      ref.invalidate(documentosPendientesFacturaProvider);
      ref.invalidate(secuenciasNcfListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Factura emitida: $ncf'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      final paraPdf = v.copyWith(
        numeroFactura: ncf,
        estadoDocumento: EstadoDocumento.facturado,
      );
      final imprimir = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Factura emitida'),
          content: Text('NCF: $ncf\n¿Imprimir comprobante?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Después'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Imprimir'),
            ),
          ],
        ),
      );
      if (imprimir == true && mounted) {
        try {
          var pdfVenta = paraPdf;
          final full = await ref
              .read(ventasRepositoryProvider)
              .obtenerVentaPorId(v.id!);
          if (full != null) {
            pdfVenta = full.copyWith(
              numeroFactura: ncf,
              estadoDocumento: EstadoDocumento.facturado,
            );
          }
          if (pdfVenta.detalles.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Factura emitida pero sin líneas de producto en BD.',
                ),
                backgroundColor: AppColors.warning,
              ),
            );
          } else {
            await ComprobantePdf.imprimirFactura(
              pdfVenta,
              empresa: ref.read(configuracionControllerProvider).valueOrNull,
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No se pudo imprimir: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
      setState(() {
        _seleccion = null;
        _emitiendo = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _emitiendo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override

  Widget build(BuildContext context) {
    final async = ref.watch(documentosPendientesFacturaProvider);
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);

    return AppScaffold(
      title: 'EMITIR FACTURA',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/sales');
          }
        },
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (docs) {
            final lista = _ListaDocs(
              docs: docs,
              fmt: _fmt,
              seleccionadoId: _seleccion?.id,
              onTap: _seleccionar,
            );
            final panel = _seleccion == null
                ? _PanelVacio(
                    icon: Icons.receipt_long_outlined,
                    texto: docs.isEmpty
                        ? 'No hay cotizaciones pendientes de facturar.'
                        : 'Seleccione un documento de la lista para emitir el NCF.',
                  )
                : _PanelEmitir(
                    venta: _seleccion!,
                    tipoNcf: _tipoNcf,
                    emitiendo: _emitiendo,
                    onTipo: (t) => setState(() => _tipoNcf = t),
                    onEmitir: _emitir,
                  );

            return Padding(
              padding: EdgeInsets.fromLTRB(
                mobile ? 16 : 20,
                mobile ? 12 : 16,
                mobile ? 16 : 20,
                20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Documentos listos',
                    style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cotizado (contado) o aprobado (crédito), sin NCF.  B01 · B02',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: desktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(width: 380, child: lista),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SingleChildScrollView(child: panel),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Lista ocupa el espacio libre (sin altura fija)
                              Expanded(child: lista),
                              const SizedBox(height: 12),
                              // Panel visible abajo, scrollea si no cabe
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.sizeOf(context).height * 0.42,
                                ),
                                child: SingleChildScrollView(child: panel),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ListaDocs extends StatelessWidget {
  const _ListaDocs({
    required this.docs,
    required this.fmt,
    required this.seleccionadoId,
    required this.onTap,
  });
  final List<Venta> docs;
  final NumberFormat fmt;
  final int? seleccionadoId;
  final void Function(Venta) onTap;

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return AppCard(
        child: Center(
          child: Text(
            'Sin pendientes',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        itemCount: docs.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, i) {
          final d = docs[i];
          final sel = seleccionadoId == d.id;
          final est = d.estadoDocumento == EstadoDocumento.aprobado
              ? 'Aprobado'
              : 'Cotizado';
          return Material(
            color: sel
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            child: InkWell(
              onTap: () => onTap(d),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      sel
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.numeroCotizacion,
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${d.nombreCliente ?? 'Cliente #${d.clienteId}'} · $est',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      fmt.format(d.montoTotal),
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PanelVacio extends StatelessWidget {
  const _PanelVacio({required this.icon, required this.texto});
  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColors.grey300),
              const SizedBox(height: 12),
              Text(
                texto,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelEmitir extends StatelessWidget {
  const _PanelEmitir({
    required this.venta,
    required this.tipoNcf,
    required this.emitiendo,
    required this.onTipo,
    required this.onEmitir,
  });
  final Venta venta;
  final String tipoNcf;
  final bool emitiendo;
  final ValueChanged<String> onTipo;
  final VoidCallback onEmitir;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emitir NCF',
                      style: AppTypography.labelLarge
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${venta.numeroCotizacion} · ${venta.nombreCliente ?? 'Cliente'}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Tipo de comprobante',
            style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('B02 · Consumidor final'),
                selected: tipoNcf == 'B02',
                onSelected: (_) => onTipo('B02'),
              ),
              ChoiceChip(
                label: const Text('B01 · Crédito fiscal'),
                selected: tipoNcf == 'B01',
                onSelected: (_) => onTipo('B01'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tipoNcf == 'B01'
                ? 'Requiere RNC del cliente (crédito fiscal).'
                : 'Consumidor final / sin RNC.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: emitiendo ? null : onEmitir,
            icon: emitiendo
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check, size: 20),
            label: Text(emitiendo ? 'Emitiendo…' : 'Emitir $tipoNcf'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}



