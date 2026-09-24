import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuenta_por_cobrar.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/estado_credito.dart';
import 'package:fiscogest_rd/features/creditos/presentation/providers/credito_providers.dart';

final cuentasCobrarListaProvider =
    FutureProvider.autoDispose<List<CuentaPorCobrar>>((ref) async {
  final repo = ref.watch(cuentaPorCobrarRepositoryProvider);
  return repo.listarCuentas();
});

final creditoTotalesProvider =
    FutureProvider.autoDispose<({double porCobrar, double vencido, int clientes})>(
  (ref) async {
    final repo = ref.watch(cuentaPorCobrarRepositoryProvider);
    final porCobrar = await repo.totalPorCobrar();
    final vencido = await repo.totalVencido();
    final clientes = await repo.cantidadClientesConDeuda();
    return (porCobrar: porCobrar, vencido: vencido, clientes: clientes);
  },
);

class CuentasCobrarPage extends ConsumerWidget {
  const CuentasCobrarPage({super.key});

  static const String routeName = 'credito-cuentas';
  static const String path = '/creditos/cuentas';

  static final _fmt = NumberFormat('#,##0.00', 'es_DO');
  static final _fmtFecha = DateFormat('dd/MM/yyyy');

  StatusChipType _chipType(EstadoCredito e) {
    return switch (e) {
      EstadoCredito.pagado => StatusChipType.success,
      EstadoCredito.vencido => StatusChipType.error,
      EstadoCredito.proximoAVencer => StatusChipType.warning,
      EstadoCredito.alDia => StatusChipType.info,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cuentasCobrarListaProvider);
    final totales = ref.watch(creditoTotalesProvider);

    return AppScaffold(
      title: 'CUENTAS POR COBRAR',
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                AppSpacing.m,
                AppSpacing.m,
                8,
              ),
              child: totales.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (t) => Row(
                  children: [
                    Expanded(
                      child: _Kpi(
                        label: 'Por cobrar',
                        value: 'RD\$ ${_fmt.format(t.porCobrar)}',
                      ),
                    ),
                    AppLayout.hS,
                    Expanded(
                      child: _Kpi(
                        label: 'Vencido',
                        value: 'RD\$ ${_fmt.format(t.vencido)}',
                      ),
                    ),
                    AppLayout.hS,
                    Expanded(
                      child: _Kpi(
                        label: 'Clientes',
                        value: '${t.clientes}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    '$e',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.error),
                  ),
                ),
                data: (lista) {
                  if (lista.isEmpty) {
                    return Center(
                      child: Text(
                        'No hay cuentas por cobrar registradas',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(cuentasCobrarListaProvider);
                      ref.invalidate(creditoTotalesProvider);
                    },
                    child: ListView.separated(
                      padding: AppLayout.pantallaPadding,
                      itemCount: lista.length,
                      separatorBuilder: (_, __) => AppLayout.vS,
                      itemBuilder: (_, i) {
                        final c = lista[i];
                        return AppCard(
                          borderColor: AppColors.border,
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
                                      c.numero ?? 'CXC-${c.id}',
                                      style: AppTypography.bodyMedium
                                          .copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      c.clienteNombre ??
                                          'Cliente #${c.clienteId}',
                                      style: AppTypography.bodySmall
                                          .copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      'Vence: ${_fmtFecha.format(c.fechaVencimiento)}'
                                      '${c.ventaId != null ? ' · Venta #${c.ventaId}' : ''}',
                                      style: AppTypography.bodySmall
                                          .copyWith(
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
                                    'RD\$ ${_fmt.format(c.saldoPendiente)}',
                                    style: AppTypography.bodyMedium
                                        .copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  StatusChip(
                                    label: c.estado.nombre.toUpperCase(),
                                    type: _chipType(c.estado),
                                    dense: true,
                                  ),
                                ],
                              ),
                            ],
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
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: AppColors.border,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.bodyMedium
                .copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
