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

class HistorialFacturasPage extends ConsumerWidget {
  const HistorialFacturasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(historialFacturasProvider);
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);
    final int maxW = desktop ? 1100 : (mobile ? 520 : 720);
    final fmt = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$');
    final fechaFmt = DateFormat('dd/MM/yyyy HH:mm');

    return AppScaffold(
      title: 'HISTORIAL DE FACTURAS',
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
                              'Facturas emitidas',
                              style: AppTypography.h4.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            AppLayout.vXs,
                            Text(
                              'Documentos con NCF o estado facturado.',
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
                            'Aún no hay facturas emitidas.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        for (final d in docs) ...[
                          AppCard(
                            borderColor: AppColors.border,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        (d.numeroFactura ?? '').trim().isEmpty
                                            ? d.numeroCotizacion
                                            : d.numeroFactura!,
                                        style: AppTypography.labelLarge.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      fmt.format(d.montoTotal),
                                      style: AppTypography.labelLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                AppLayout.vXs,
                                Text(
                                  '${d.numeroCotizacion} · '
                                  '${d.nombreCliente ?? 'Cliente #${d.clienteId}'}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  fechaFmt.format(d.fechaRegistro),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                AppLayout.vS,
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      try {
                                        await ComprobantePdf.imprimirFactura(d, empresa: ref.read(configuracionControllerProvider).valueOrNull);
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text('$e'),
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.print, size: 18),
                                    label: const Text('Imprimir'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppLayout.vS,
                        ],

                      AppLayout.vL,
                      Text(
                        'Notas de crédito',
                        style: AppTypography.h4.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      AppLayout.vS,
                      Consumer(
                        builder: (context, ref, _) {
                          final ncs = ref.watch(notasCreditoListProvider);
                          return ncs.when(
                            loading: () => const SizedBox.shrink(),
                            error: (e, _) => Text('$e'),
                            data: (rows) {
                              if (rows.isEmpty) {
                                return Text(
                                  'Sin notas de crédito.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                );
                              }
                              return Column(
                                children: [
                                  for (final n in rows) ...[
                                    AppCard(
                                      borderColor: AppColors.border,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            n.ncf,
                                            style: AppTypography.labelLarge
                                                .copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            'Origen: ${n.ncfFacturaOrigen}',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            n.motivo,
                                            style: AppTypography.bodySmall,
                                          ),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton.icon(
                                              onPressed: () async {
                                                await ComprobantePdf.imprimirNc(
                                                  ncfNc: n.ncf,
                                                  ncfOrigen: n.ncfFacturaOrigen,
                                                  cliente:
                                                      n.nombreCliente ?? '',
                                                  monto: n.monto,
                                                  motivo: n.motivo,
                                                );
                                              },
                                              icon: const Icon(Icons.print,
                                                  size: 18),
                                              label: const Text('Imprimir NC'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AppLayout.vS,
                                  ],
                                ],
                              );
                            },
                          );
                        },
                      ),
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
