import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/facturacion/presentation/providers/facturacion_providers.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';

final facturasParaNcProvider =
    FutureProvider.autoDispose<List<Venta>>((ref) async {
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
  final _fmt = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$');
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
      final r = await ref.read(emitirNcServiceProvider).emitir(
            facturaVentaId: _sel!.id!,
            motivo: _motivo.text,
          );
      ref.invalidate(secuenciasNcfListProvider);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Nota de crédito emitida'),
          content: Text(
            'NC: ${r.ncfNc}\n'
            'Factura origen: ${r.ncfFacturaOrigen}\n'
            'Motivo: ${r.motivo}\n\n'
            'Guarde este NCF. La anulación de stock/CXC se completará en una fase posterior.',
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
    final async = ref.watch(facturasParaNcProvider);
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);
    final int maxW = desktop ? 1100 : (mobile ? 520 : 720);

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
            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: AppLayout.pantallaPadding.add(
                  const EdgeInsets.only(bottom: 24),
                ),
                child: AppLayout.centerConstrained(
                  maxWidth: maxW,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        borderColor: AppColors.border,
                        child: Text(
                          'Seleccione una factura (NCF B01/B02) y el motivo. '
                          'Se asigna secuencia B04.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      AppLayout.vM,
                      if (docs.isEmpty)
                        AppCard(
                          borderColor: AppColors.border,
                          child: Text(
                            'No hay facturas con NCF para anular/ajustar.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        for (final d in docs) ...[
                          AppCard(
                            borderColor: _sel?.id == d.id
                                ? AppColors.primary
                                : AppColors.border,
                            onTap: () => setState(() => _sel = d),
                            child: Row(
                              children: [
                                Icon(
                                  _sel?.id == d.id
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: AppColors.primary,
                                ),
                                AppLayout.hS,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d.numeroFactura ?? '',
                                        style: AppTypography.labelLarge
                                            .copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${d.numeroCotizacion} · '
                                        '${d.nombreCliente ?? 'Cliente'}',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(fmt.format(d.montoTotal)),
                              ],
                            ),
                          ),
                          AppLayout.vS,
                        ],
                      if (_sel != null) ...[
                        AppLayout.vM,
                        AppTextField(
                          label: 'Motivo de la NC',
                          controller: _motivo,
                        ),
                        AppLayout.vM,
                        AppButton(
                          text: _busy ? 'Emitiendo…' : 'Emitir B04',
                          onPressed: _busy ? null : _emitir,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  NumberFormat get fmt => _fmt;
}
