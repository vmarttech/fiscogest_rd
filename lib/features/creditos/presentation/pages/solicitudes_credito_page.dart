import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

final solicitudesCreditoProvider =
    FutureProvider.autoDispose<List<Venta>>((ref) async {
  final repo = ref.watch(ventasRepositoryProvider);
  // Preferir API de cotizaciones si existe; fallback listar y filtrar
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

  static final _fmt = NumberFormat('#,##0.00', 'es_DO');
  static final _fmtFecha = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(solicitudesCreditoProvider);
    final mobile = AppBreakpoints.isMobile(context);

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
            if (lista.isEmpty) {
              return Center(
                child: Text(
                  'No hay cotizaciones en crédito pendientes',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(solicitudesCreditoProvider),
              child: ListView.separated(
                padding: AppLayout.pantallaPadding,
                itemCount: lista.length,
                separatorBuilder: (_, __) => AppLayout.vS,
                itemBuilder: (_, i) {
                  final v = lista[i];
                  final pendiente =
                      v.estadoDocumento == EstadoDocumento.enCredito;
                  return AppCard(
                    borderColor: AppColors.border,
                    onTap: () => context.push(
                      '/creditos/solicitudes/${v.id}',
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: mobile ? 14 : 16,
                      vertical: mobile ? 12 : 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.numeroCotizacion,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                v.nombreCliente?.isNotEmpty == true
                                    ? v.nombreCliente!
                                    : 'Cliente #${v.clienteId}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                _fmtFecha.format(v.fecha),
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'RD\$ ${_fmt.format(v.montoTotal)}',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            StatusChip(
                              label: pendiente ? 'EN ANÁLISIS' : v.estadoDocumento.name.toUpperCase(),
                              type: pendiente
                                  ? StatusChipType.warning
                                  : StatusChipType.info,
                              dense: true,
                            ),
                          ],
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
