import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuenta_por_cobrar.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/estado_credito.dart';
import 'package:fiscogest_rd/features/creditos/presentation/providers/credito_providers.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_providers.dart';

final cuentasCobrarListaProvider =
    FutureProvider.autoDispose<List<CuentaPorCobrar>>((ref) async {
  final repo = ref.watch(cuentaPorCobrarRepositoryProvider);
  final lista = await repo.listarCuentas();
  try {
    final clientesRepo = ref.watch(clienteRepositoryProvider);
    final out = <CuentaPorCobrar>[];
    for (final c in lista) {
      if (c.clienteNombre != null && c.clienteNombre!.isNotEmpty) {
        out.add(c);
        continue;
      }
      final cli = await clientesRepo.obtenerClientePorId(c.clienteId);
      final nombre = cli?.nombre ?? 'Cliente #${c.clienteId}';
      out.add(c.copyWith(clienteNombre: nombre));
    }
    return out;
  } catch (_) {
    return lista;
  }
});

final creditoTotalesProvider = FutureProvider.autoDispose<
    ({double porCobrar, double vencido, int clientes})>((ref) async {
  final repo = ref.watch(cuentaPorCobrarRepositoryProvider);
  final porCobrar = await repo.totalPorCobrar();
  final vencido = await repo.totalVencido();
  final clientes = await repo.cantidadClientesConDeuda();
  return (porCobrar: porCobrar, vencido: vencido, clientes: clientes);
});

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
    final mobile = AppBreakpoints.isMobile(context);

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
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
          padding: EdgeInsets.fromLTRB(
            mobile ? 16 : 20,
            mobile ? 12 : 16,
            mobile ? 16 : 20,
            12,
          ),
          child: AppLayout.centerConstrained(
            maxWidth: mobile ? 520 : 920,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              totales.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (t) => LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth;
                    final cols = w > 720 ? 3 : (w > 420 ? 3 : 1);
                    const gap = 10.0;
                    final tileW = cols == 1
                        ? w
                        : (w - gap * (cols - 1)) / cols;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        SizedBox(
                          width: tileW,
                          child: _Kpi(
                            label: 'Por cobrar',
                            value: 'RD\$ ${_fmt.format(t.porCobrar)}',
                          ),
                        ),
                        SizedBox(
                          width: tileW,
                          child: _Kpi(
                            label: 'Vencido',
                            value: 'RD\$ ${_fmt.format(t.vencido)}',
                          ),
                        ),
                        SizedBox(
                          width: tileW,
                          child: _Kpi(
                            label: 'Clientes',
                            value: '${t.clientes}',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Cartera',
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Seleccione una cuenta para ver cuotas y registrar cobros.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.grey600,
                ),
              ),
              const SizedBox(height: 12),
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
                      return AppCard(
                        child: Center(
                          child: Text(
                            'No hay cuentas por cobrar registradas',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }
                    return AppCard(
                      padding: EdgeInsets.zero,
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(cuentasCobrarListaProvider);
                          ref.invalidate(creditoTotalesProvider);
                        },
                        child: ListView.separated(
                          itemCount: lista.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: AppColors.border,
                          ),
                          itemBuilder: (_, i) {
                            final c = lista[i];
                            return InkWell(
                              onTap: () {
                                final id = c.id;
                                if (id == null) return;
                                context.push('/creditos/cuentas/$id');
                              },
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
                                            c.numero ?? 'CXC-${c.id}',
                                            style: AppTypography.labelMedium
                                                .copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            c.clienteNombre ??
                                                'Cliente #${c.clienteId}',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color: AppColors.grey600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'RD\$ ${_fmt.format(c.saldoPendiente)}',
                                          style: AppTypography.labelMedium
                                              .copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        StatusChip(
                                          label: c.estado.nombre.toUpperCase(),
                                          type: _chipType(c.estado),
                                          dense: true,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                      color: AppColors.grey400,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
