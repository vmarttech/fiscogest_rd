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
          await ComprobantePdf.imprimirFactura(paraPdf, empresa: ref.read(configuracionControllerProvider).valueOrNull);
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
                            onTap: () => _seleccionar(d),
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
                              Text(
                                'Tipo de comprobante',
                                style: AppTypography.labelLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              AppLayout.vS,
                              Wrap(
                                spacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text('B02 · Consumidor final'),
                                    selected: _tipoNcf == 'B02',
                                    onSelected: (_) => setState(() {
                                      _tipoNcf = 'B02';
                                    }),
                                  ),
                                  ChoiceChip(
                                    label: const Text('B01 · Crédito fiscal'),
                                    selected: _tipoNcf == 'B01',
                                    onSelected: (_) => setState(() {
                                      _tipoNcf = 'B01';
                                    }),
                                  ),
                                ],
                              ),
                              AppLayout.vXs,
                              Text(
                                _tipoNcf == 'B01'
                                    ? 'Requiere RNC del cliente (crédito fiscal).'
                                    : 'Consumidor final / sin RNC.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
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
