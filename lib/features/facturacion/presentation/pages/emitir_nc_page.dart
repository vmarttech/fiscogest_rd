import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/facturacion/presentation/providers/facturacion_providers.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

final facturasParaNcProvider = FutureProvider.autoDispose<List<Venta>>((
  ref,
) async {
  final repo = ref.watch(ventasRepositoryProvider);
  final list = await repo.listarCotizaciones();
  return list.where((v) {
    final ncf = (v.numeroFactura ?? '').trim();
    return ncf.isNotEmpty &&
        !ncf.startsWith('B04') &&
        (v.estadoDocumento == EstadoDocumento.facturado || ncf.isNotEmpty);
  }).toList();
});

class EmitirNcPage extends ConsumerStatefulWidget {
  const EmitirNcPage({super.key});

  @override
  ConsumerState<EmitirNcPage> createState() => _EmitirNcPageState();
}

class _EmitirNcPageState extends ConsumerState<EmitirNcPage> {
  final String Function(num) _fmt = formatRd;
  final _motivo = TextEditingController();
  Venta? _sel;
  bool _busy = false;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _emitir() async {
    if (_sel?.id == null) return;
    setState(() => _busy = true);
    try {
      final r = await ref
          .read(emitirNcServiceProvider)
          .emitir(facturaVentaId: _sel!.id!, motivo: _motivo.text);
      ref.invalidate(secuenciasNcfListProvider);
      ref.invalidate(notasCreditoListProvider);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Nota de crédito emitida'),
          content: Text(
            'NC: ${r.ncfNc}\n'
            'Factura origen: ${r.ncfFacturaOrigen}\n'
            'Motivo: ${r.motivo}\n\n'
            'Inventario devuelto y CxC anulada (si aplicaba). Guarde este NCF.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      setState(() {
        _sel = null;
        _motivo.clear();
        _busy = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        FiscoGestNotifications.show(
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
    final async = ref.watch(facturasParaNcProvider);
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);

    return AppScaffold(
      title: 'EMITIR NOTA DE CRÉDITO',
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
            final lista = _ListaFacturasNc(
              docs: docs,
              fmt: _fmt,
              seleccionadoId: _sel?.id,
              onTap: (d) => setState(() => _sel = d),
            );
            final panel = _sel == null
                ? _NcPanelVacio(
                    texto: docs.isEmpty
                        ? 'No hay facturas con NCF B01/B02.\nPrimero emita factura en Facturación.'
                        : 'Seleccione una factura para emitir la nota de crédito (B04).',
                  )
                : _NcPanelEmitir(
                    venta: _sel!,
                    motivo: _motivo,
                    busy: _busy,
                    fmt: _fmt,
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
                    'Facturas con NCF',
                    style: AppTypography.h4.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Se asigna secuencia B04. Inventario y CxC se ajustan según reglas.',
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
                              Expanded(child: panel),
                            ],
                          )
                        : ListView(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.sizeOf(context).height * 0.32,
                                child: lista,
                              ),
                              const SizedBox(height: 12),
                              panel,
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

class _ListaFacturasNc extends StatelessWidget {
  const _ListaFacturasNc({
    required this.docs,
    required this.fmt,
    required this.seleccionadoId,
    required this.onTap,
  });
  final List<Venta> docs;
  final String Function(num) fmt;
  final int? seleccionadoId;
  final void Function(Venta) onTap;

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return AppCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Sin facturas disponibles',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
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
          return Material(
            color: sel
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            child: InkWell(
              onTap: () => onTap(d),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      sel ? Icons.radio_button_checked : Icons.radio_button_off,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.numeroFactura ?? '',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${d.numeroCotizacion} · ${d.nombreCliente ?? 'Cliente'}',
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
                      fmt(d.montoTotal),
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

class _NcPanelVacio extends StatelessWidget {
  const _NcPanelVacio({required this.texto});
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
              const Icon(
                Icons.assignment_return_outlined,
                size: 48,
                color: AppColors.grey300,
              ),
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

class _NcPanelEmitir extends StatelessWidget {
  const _NcPanelEmitir({
    required this.venta,
    required this.motivo,
    required this.busy,
    required this.fmt,
    required this.onEmitir,
  });
  final Venta venta;
  final TextEditingController motivo;
  final bool busy;
  final String Function(num) fmt;
  final VoidCallback onEmitir;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_return_outlined,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emitir B04',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${venta.numeroFactura} · ${fmt(venta.montoTotal)}',
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
          AppTextField(label: 'Motivo de la NC', controller: motivo),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: busy ? null : onEmitir,
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check, size: 20),
            label: Text(busy ? 'Emitiendo…' : 'Emitir B04'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
