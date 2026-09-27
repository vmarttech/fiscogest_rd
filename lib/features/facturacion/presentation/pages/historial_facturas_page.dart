import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';
import 'package:fiscogest_rd/features/facturacion/presentation/pdf/comprobante_pdf.dart';
import 'package:fiscogest_rd/features/facturacion/presentation/providers/facturacion_providers.dart';

final historialFacturasProvider =
    FutureProvider.autoDispose<List<Venta>>((ref) async {
  final repo = ref.watch(ventasRepositoryProvider);
  final list = await repo.listarCotizaciones();
  final facturadas = list.where((v) {
    final ncf = (v.numeroFactura ?? '').trim();
    return ncf.isNotEmpty ||
        v.estadoDocumento == EstadoDocumento.facturado;
  }).toList();
  facturadas.sort((a, b) {
    final fa = a.fechaRegistro;
    final fb = b.fechaRegistro;
    return fb.compareTo(fa);
  });
  return facturadas;
});


class HistorialFacturasPage extends ConsumerStatefulWidget {
  const HistorialFacturasPage({super.key});

  @override
  ConsumerState<HistorialFacturasPage> createState() =>
      _HistorialFacturasPageState();
}

class _HistorialFacturasPageState extends ConsumerState<HistorialFacturasPage> {
  Venta? _sel;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(historialFacturasProvider);
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);
    final fmt = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$');
    final fechaFmt = DateFormat('dd/MM/yyyy HH:mm');

    return AppScaffold(
      title: 'HISTORIAL',
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
            final lista = AppCard(
              padding: EdgeInsets.zero,
              child: docs.isEmpty
                  ? Center(
                      child: Text(
                        'Aún no hay facturas emitidas.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, i) {
                        final d = docs[i];
                        final sel = _sel?.id == d.id;
                        final ncf = (d.numeroFactura ?? '').trim();
                        return Material(
                          color: sel
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => _sel = d),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ncf.isEmpty ? d.numeroCotizacion : ncf,
                                          style: AppTypography.labelMedium
                                              .copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          '${d.nombreCliente ?? 'Cliente'} · ${fechaFmt.format(d.fechaRegistro)}',
                                          style:
                                              AppTypography.bodySmall.copyWith(
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

            final panel = _sel == null
                ? AppCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.history,
                                size: 48, color: AppColors.grey300),
                            const SizedBox(height: 12),
                            Text(
                              docs.isEmpty
                                  ? 'Sin comprobantes aún.'
                                  : 'Seleccione un documento para ver detalle e imprimir.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          (_sel!.numeroFactura ?? '').trim().isEmpty
                              ? _sel!.numeroCotizacion
                              : _sel!.numeroFactura!,
                          style: AppTypography.h4.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cotización: ${_sel!.numeroCotizacion}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Cliente: ${_sel!.nombreCliente ?? 'Cliente #${_sel!.clienteId}'}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Fecha: ${fechaFmt.format(_sel!.fechaRegistro)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          fmt.format(_sel!.montoTotal),
                          style: AppTypography.h3.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Notas de crédito',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Consumer(
                          builder: (context, ref, _) {
                            final ncsAsync =
                                ref.watch(notasCreditoListProvider);
                            final ncfSel =
                                (_sel?.numeroFactura ?? '').trim();
                            return ncsAsync.when(
                              loading: () => const LinearProgressIndicator(
                                minHeight: 2,
                              ),
                              error: (e, _) => Text(
                                '$e',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                              data: (rows) {
                                final relacionadas = [
                                  for (final n in rows)
                                    if (ncfSel.isNotEmpty &&
                                        (n.ncfFacturaOrigen).trim() ==
                                            ncfSel)
                                      n,
                                ];
                                if (relacionadas.isEmpty) {
                                  return Text(
                                    'Sin notas de crédito para este comprobante.',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  );
                                }
                                return Column(
                                  children: [
                                    for (final n in relacionadas)
                                      Container(
                                        width: double.infinity,
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.04),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    n.ncf,
                                                    style: AppTypography
                                                        .labelMedium
                                                        .copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  Text(
                                                    n.motivo,
                                                    style: AppTypography
                                                        .bodySmall
                                                        .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                await ComprobantePdf
                                                    .imprimirNc(
                                                  ncfNc: n.ncf,
                                                  ncfOrigen:
                                                      n.ncfFacturaOrigen,
                                                  cliente:
                                                      n.nombreCliente ?? '',
                                                  monto: n.monto,
                                                  motivo: n.motivo,
                                                );
                                              },
                                              child: const Text('Imprimir'),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () async {
                            try {
                              await ComprobantePdf.imprimirFactura(
                                _sel!,
                                empresa: ref
                                    .read(configuracionControllerProvider)
                                    .valueOrNull,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.print, size: 20),
                          label: const Text('Imprimir comprobante'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  );

            return Padding(
              padding: EdgeInsets.fromLTRB(
                mobile ? 16 : 20,
                mobile ? 12 : 16,
                mobile ? 16 : 20,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Facturas emitidas',
                    style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Documentos con NCF o estado facturado.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: desktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(width: 400, child: lista),
                              const SizedBox(width: 16),
                              Expanded(child: panel),
                            ],
                          )
                        : ListView(
                            children: [
                              SizedBox(height: 260, child: lista),
                              const SizedBox(height: 12),
                              SizedBox(height: 280, child: panel),
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
