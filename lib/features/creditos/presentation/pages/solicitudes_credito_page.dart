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
    // Cotizaciones a crédito viven en listarCotizaciones; por si alguna
    // quedó en listarVentas, unimos ambas y deduplicamos por id.
    final cotiz = await repo.listarCotizaciones();
    final ventas = await repo.listarVentas();
    final byId = <int?, Venta>{};
    for (final v in [...cotiz, ...ventas]) {
      if (v.estadoDocumento != EstadoDocumento.enCredito) continue;
      if (v.id != null) {
        byId[v.id] = v;
      }
    }
    final list = byId.values.toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return list;
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
      showAppBar: !desktop,
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
                mobile ? 16 : 24,
                mobile ? 12 : 20,
                mobile ? 16 : 24,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const EnterprisePageHeader(
                    title: 'Solicitudes de crédito',
                    subtitle: 'Pendientes de análisis y aprobación',
                    showBack: true,
                    backFallbackRoute: '/creditos',
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: desktop ? 1400 : double.infinity,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!desktop) ...[
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
                            ],
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
                                  : LayoutBuilder(
                                      builder: (context, constraints) {
                                        final columns =
                                            constraints.maxWidth >= 1200
                                            ? 3
                                            : constraints.maxWidth >= 680
                                            ? 2
                                            : 1;
                                        return RefreshIndicator(
                                          onRefresh: () async => ref.invalidate(
                                            solicitudesCreditoProvider,
                                          ),
                                          child: GridView.builder(
                                            physics:
                                                const AlwaysScrollableScrollPhysics(),
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            itemCount: lista.length,
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: columns,
                                                  crossAxisSpacing: 14,
                                                  mainAxisSpacing: 14,
                                                  mainAxisExtent: mobile
                                                      ? 158
                                                      : 148,
                                                ),
                                            itemBuilder: (context, index) {
                                              final venta = lista[index];
                                              return _TarjetaSolicitudCredito(
                                                venta: venta,
                                                fecha: _fmtFecha.format(
                                                  venta.fecha,
                                                ),
                                                onTap: () => context.push(
                                                  '/creditos/solicitudes/${venta.id}',
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
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

class _TarjetaSolicitudCredito extends StatelessWidget {
  const _TarjetaSolicitudCredito({
    required this.venta,
    required this.fecha,
    required this.onTap,
  });

  final Venta venta;
  final String fecha;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enAnalisis = venta.estadoDocumento == EstadoDocumento.enCredito;
    final cliente = venta.nombreCliente?.trim().isNotEmpty == true
        ? venta.nombreCliente!.trim()
        : 'Cliente #${venta.clienteId}';

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  venta.numeroCotizacion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(
                label: enAnalisis
                    ? 'EN ANÁLISIS'
                    : venta.estadoDocumento.name.toUpperCase(),
                type: enAnalisis ? StatusChipType.warning : StatusChipType.info,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            cliente,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: AppColors.grey600),
          ),
          const Spacer(),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  fecha,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  formatRd(venta.montoTotal),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.grey400),
            ],
          ),
        ],
      ),
    );
  }
}
