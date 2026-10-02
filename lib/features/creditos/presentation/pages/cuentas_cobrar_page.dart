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
    FutureProvider.autoDispose<List<CuentaPorCobrarBusqueda>>((ref) async {
      final repo = ref.watch(cuentaPorCobrarRepositoryProvider);
      final lista = await repo.listarCuentas();
      try {
        final clientesRepo = ref.watch(clienteRepositoryProvider);
        final idsClientes = lista.map((c) => c.clienteId).toSet().toList();
        final clientes = await Future.wait(
          idsClientes.map(clientesRepo.obtenerClientePorId),
        );
        final documentos = <int, String>{};
        final nombres = <int, String>{};
        for (var i = 0; i < idsClientes.length; i++) {
          final cliente = clientes[i];
          if (cliente != null) {
            documentos[idsClientes[i]] = cliente.rncCedula;
            nombres[idsClientes[i]] = cliente.nombre;
          }
        }
        return lista.map((cuenta) {
          final nombre = cuenta.clienteNombre?.trim().isNotEmpty == true
              ? cuenta.clienteNombre!
              : nombres[cuenta.clienteId] ?? 'Cliente #${cuenta.clienteId}';
          return CuentaPorCobrarBusqueda(
            cuenta: cuenta.copyWith(clienteNombre: nombre),
            documentoCliente: documentos[cuenta.clienteId] ?? '',
          );
        }).toList();
      } catch (_) {
        return lista
            .map(
              (cuenta) =>
                  CuentaPorCobrarBusqueda(cuenta: cuenta, documentoCliente: ''),
            )
            .toList();
      }
    });

final creditoTotalesProvider =
    FutureProvider.autoDispose<
      ({double porCobrar, double vencido, int clientes})
    >((ref) async {
      final repo = ref.watch(cuentaPorCobrarRepositoryProvider);
      final porCobrar = await repo.totalPorCobrar();
      final vencido = await repo.totalVencido();
      final clientes = await repo.cantidadClientesConDeuda();
      return (porCobrar: porCobrar, vencido: vencido, clientes: clientes);
    });

class CuentaPorCobrarBusqueda {
  const CuentaPorCobrarBusqueda({
    required this.cuenta,
    required this.documentoCliente,
  });

  final CuentaPorCobrar cuenta;
  final String documentoCliente;
}

class CuentasCobrarPage extends ConsumerStatefulWidget {
  const CuentasCobrarPage({super.key});

  static const String routeName = 'credito-cuentas';
  static const String path = '/creditos/cuentas';

  @override
  ConsumerState<CuentasCobrarPage> createState() => _CuentasCobrarPageState();
}

class _CuentasCobrarPageState extends ConsumerState<CuentasCobrarPage> {
  static final _fmtFecha = DateFormat('dd/MM/yyyy');
  final _busquedaController = TextEditingController();
  String _textoBusqueda = '';

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  String _normalizarDocumento(String valor) =>
      valor.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  StatusChipType _chipType(EstadoCredito e) {
    return switch (e) {
      EstadoCredito.pagado => StatusChipType.success,
      EstadoCredito.vencido => StatusChipType.error,
      EstadoCredito.proximoAVencer => StatusChipType.warning,
      EstadoCredito.alDia => StatusChipType.info,
    };
  }

  @override
  Widget build(BuildContext context) {
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
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            mobile ? 16 : 20,
            mobile ? 12 : 16,
            mobile ? 16 : 20,
            12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: mobile ? double.infinity : 920,
                    ),
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
                                      value: formatRd(t.porCobrar),
                                    ),
                                  ),
                                  SizedBox(
                                    width: tileW,
                                    child: _Kpi(
                                      label: 'Vencido',
                                      value: formatRd(t.vencido),
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
                        Align(
                          alignment: Alignment.centerRight,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: mobile ? 280 : 340,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: TextField(
                                controller: _busquedaController,
                                onChanged: (valor) =>
                                    setState(() => _textoBusqueda = valor),
                                decoration: InputDecoration(
                                  hintText: 'Buscar nombre, RNC o cédula',
                                  isDense: true,
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    size: 20,
                                  ),
                                  suffixIcon: _textoBusqueda.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: 'Limpiar búsqueda',
                                          onPressed: () {
                                            _busquedaController.clear();
                                            setState(() => _textoBusqueda = '');
                                          },
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 18,
                                          ),
                                        ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: async.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) => Center(
                              child: Text(
                                '$e',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                            data: (lista) {
                              final consulta = _textoBusqueda
                                  .trim()
                                  .toLowerCase();
                              final consultaDocumento = _normalizarDocumento(
                                consulta,
                              );
                              final filtradas = lista.where((item) {
                                final nombre = (item.cuenta.clienteNombre ?? '')
                                    .toLowerCase();
                                final documento = _normalizarDocumento(
                                  item.documentoCliente,
                                );
                                return consulta.isEmpty ||
                                    nombre.contains(consulta) ||
                                    (consultaDocumento.isNotEmpty &&
                                        documento.contains(consultaDocumento));
                              }).toList();
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
                              if (filtradas.isEmpty) {
                                return AppCard(
                                  child: Center(
                                    child: Text(
                                      'No hay clientes que coincidan con la búsqueda.',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
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
                                    itemCount: filtradas.length,
                                    separatorBuilder: (_, __) => const Divider(
                                      height: 1,
                                      color: AppColors.border,
                                    ),
                                    itemBuilder: (_, i) {
                                      final c = filtradas[i].cuenta;
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
                                                      style: AppTypography
                                                          .labelMedium
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: AppColors
                                                                .textPrimary,
                                                          ),
                                                    ),
                                                    Text(
                                                      c.clienteNombre ??
                                                          'Cliente #${c.clienteId}',
                                                      style: AppTypography
                                                          .bodySmall
                                                          .copyWith(
                                                            color: AppColors
                                                                .grey600,
                                                          ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      'Vence: ${_fmtFecha.format(c.fechaVencimiento)}'
                                                      '${c.ventaId != null ? ' · Venta #${c.ventaId}' : ''}',
                                                      style: AppTypography
                                                          .bodySmall
                                                          .copyWith(
                                                            color: AppColors
                                                                .textSecondary,
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
                                                    formatRd(c.saldoPendiente),
                                                    style: AppTypography
                                                        .labelMedium
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors
                                                              .textPrimary,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  StatusChip(
                                                    label: c.estado.nombre
                                                        .toUpperCase(),
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
            ],
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
