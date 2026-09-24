import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/facturacion/domain/emitir_factura_service.dart';
import 'package:fiscogest_rd/features/facturacion/presentation/providers/facturacion_providers.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';

class EmitirFacturaPage extends ConsumerStatefulWidget {
  const EmitirFacturaPage({super.key});

  @override
  ConsumerState<EmitirFacturaPage> createState() => _EmitirFacturaPageState();
}

class _EmitirFacturaPageState extends ConsumerState<EmitirFacturaPage> {
  final _fmt = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$');
  Venta? _seleccion;
  String _tipoNcf = 'B02';
  bool _consumidorFinal = true;
  bool _emitiendo = false;

  Future<void> _emitir() async {
    final v = _seleccion;
    if (v == null || v.id == null) return;
    setState(() => _emitiendo = true);
    try {
      final tipo = EmitirFacturaService.tipoNcfSugerido(
        consumidorFinal: _consumidorFinal,
      );
      final ncf = await ref.read(emitirFacturaServiceProvider).emitir(
            ventaId: v.id!,
            tipoNcf: tipo,
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
    final int maxW = desktop ? 1100 : (mobile ? 520 : 720);

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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Documentos listos',
                              style: AppTypography.h4.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            AppLayout.vXs,
                            Text(
                              'Cotizado (contado) o aprobado (crédito), sin NCF. '
                              'B01 = crédito fiscal · B02 = consumidor final.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppLayout.vM,
                      if (docs.isEmpty)
                        AppCard(
                          borderColor: AppColors.border,
                          child: Text(
                            'No hay cotizaciones pendientes de facturar.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        for (final d in docs) ...[
                          _DocTile(
                            venta: d,
                            fmt: _fmt,
                            seleccionado: _seleccion?.id == d.id,
                            onTap: () => setState(() {
                              _seleccion = d;
                              _consumidorFinal = true;
                              _tipoNcf = 'B02';
                            }),
                          ),
                          AppLayout.vS,
                        ],
                      if (_seleccion != null) ...[
                        AppLayout.vM,
                        AppCard(
                          borderColor: AppColors.primary,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Emitir NCF',
                                style: AppTypography.labelLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              AppLayout.vS,
                              Text(
                                '${_seleccion!.numeroCotizacion} · '
                                '${_seleccion!.nombreCliente ?? 'Cliente #${_seleccion!.clienteId}'}',
                              ),
                              AppLayout.vS,
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Consumidor final (B02)'),
                                subtitle: Text(
                                  _consumidorFinal
                                      ? 'Se emitirá B02'
                                      : 'Se emitirá B01 (crédito fiscal)',
                                ),
                                value: _consumidorFinal,
                                onChanged: (v) => setState(() {
                                  _consumidorFinal = v;
                                  _tipoNcf = v ? 'B02' : 'B01';
                                }),
                              ),
                              AppLayout.vS,
                              AppButton(
                                text: _emitiendo
                                    ? 'Emitiendo…'
                                    : 'Emitir $_tipoNcf',
                                onPressed: _emitiendo ? null : _emitir,
                              ),
                            ],
                          ),
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
}

class _DocTile extends StatelessWidget {
  const _DocTile({
    required this.venta,
    required this.fmt,
    required this.seleccionado,
    required this.onTap,
  });

  final Venta venta;
  final NumberFormat fmt;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final est = venta.estadoDocumento == EstadoDocumento.aprobado
        ? 'Aprobado'
        : 'Cotizado';
    return AppCard(
      borderColor: seleccionado ? AppColors.primary : AppColors.border,
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            seleccionado ? Icons.radio_button_checked : Icons.radio_button_off,
            color: AppColors.primary,
          ),
          AppLayout.hS,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venta.numeroCotizacion,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${venta.nombreCliente ?? 'Cliente #${venta.clienteId}'} · $est',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            fmt.format(venta.montoTotal),
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
