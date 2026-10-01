import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

final solicitudesCreditoProvider = FutureProvider.autoDispose<List<Venta>>((
  ref,
) async {
  final repo = ref.watch(ventasRepositoryProvider);
  try {
    final todas = await repo.listarVentas();
    return todas
        .where((v) => v.estadoDocumento == EstadoDocumento.enCredito)
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  } catch (_) {
    return [];
  }
});

class SolicitudesCreditoPage extends ConsumerWidget {
  const SolicitudesCreditoPage({super.key});

  static const String routeName = 'credito-solicitudes';
  static const String path = '/creditos/solicitudes';

  static final _fmtFecha = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(solicitudesCreditoProvider);
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);

    return AppScaffold(
      title: 'SOLICITUDES DE CRÉDITO',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/creditos');
          }
        },
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              '$e',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
          data: (lista) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                mobile ? 16 : 20,
                mobile ? 12 : 16,
                mobile ? 16 : 20,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: desktop ? 920 : double.infinity,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'En análisis',
                              style: AppTypography.h4.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cotizaciones en crédito pendientes de aprobación.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.grey600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: lista.isEmpty
                                  ? AppCard(
                                      child: Center(
                                        child: Text(
                                          'No hay cotizaciones en crédito pendientes',
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                      ),
                                    )
                                  : AppCard(
                                      padding: EdgeInsets.zero,
                                      child: RefreshIndicator(
                                        onRefresh: () async => ref.invalidate(
                                          solicitudesCreditoProvider,
                                        ),
                                        child: ListView.separated(
                                          itemCount: lista.length,
                                          separatorBuilder: (_, __) =>
                                              const Divider(
                                                height: 1,
                                                color: AppColors.border,
                                              ),
                                          itemBuilder: (_, i) {
                                            final v = lista[i];
                                            final pendiente =
                                                v.estadoDocumento ==
                                                EstadoDocumento.enCredito;
                                            return InkWell(
                                              onTap: () => context.push(
                                                '/creditos/solicitudes/${v.id}',
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: mobile ? 14 : 16,
                                                  vertical: 12,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            v.numeroCotizacion,
                                                            style: AppTypography
                                                                .labelMedium
                                                                .copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  color: AppColors
                                                                      .textPrimary,
                                                                ),
                                                          ),
                                                          Text(
                                                            v.nombreCliente?.isNotEmpty ==
                                                                    true
                                                                ? v.nombreCliente!
                                                                : 'Cliente #${v.clienteId}',
                                                            style: AppTypography
                                                                .bodySmall
                                                                .copyWith(
                                                                  color: AppColors
                                                                      .grey600,
                                                                ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          if (desktop)
                                                            Text(
                                                              _fmtFecha.format(
                                                                v.fecha,
                                                              ),
                                                              style: AppTypography
                                                                  .bodySmall
                                                                  .copyWith(
                                                                    color: AppColors
                                                                        .textSecondary,
                                                                    fontSize:
                                                                        11,
                                                                  ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (!desktop)
                                                      Text(
                                                        _fmtFecha.format(
                                                          v.fecha,
                                                        ),
                                                        style: AppTypography
                                                            .bodySmall
                                                            .copyWith(
                                                              color: AppColors
                                                                  .textSecondary,
                                                              fontSize: 11,
                                                            ),
                                                      ),
                                                    const SizedBox(width: 12),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      children: [
                                                        Text(
                                                          formatRd(v.montoTotal),
                                                          style: AppTypography
                                                              .labelMedium
                                                              .copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: AppColors
                                                                    .textPrimary,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        StatusChip(
                                                          label: pendiente
                                                              ? 'EN ANÁLISIS'
                                                              : v
                                                                    .estadoDocumento
                                                                    .name
                                                                    .toUpperCase(),
                                                          type: pendiente
                                                              ? StatusChipType
                                                                    .warning
                                                              : StatusChipType
                                                                    .info,
                                                          dense: true,
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                      Icons.chevron_right,
                                                      color: AppColors.grey400,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
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
