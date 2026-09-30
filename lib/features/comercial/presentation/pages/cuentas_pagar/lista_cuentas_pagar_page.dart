import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/cuenta_pagar.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/cuentas_pagar_providers.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/cuentas_pagar/detalle_cuenta_pagar_page.dart';

class ListaCuentasPagarPage extends ConsumerWidget {
  const ListaCuentasPagarPage({super.key});
  static const String routeName = 'lista-cuentas-pagar';

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '—';
    return fecha.toString().split(' ')[0];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<CuentaPagar>> cuentasAsync = ref.watch(
      listadoCuentasPagarProvider,
    );
    final double ancho = MediaQuery.of(context).size.width;
    final bool esPequena = ancho < 768;

    Widget buildEstadoTag(CuentaPagar cuenta) {
      final (Color color, String texto) = switch (cuenta.estado) {
        PagarEstado.pendiente when cuenta.estaVencida => (
          Colors.red,
          'Vencida',
        ),
        PagarEstado.pendiente => (Colors.orange, 'Pendiente'),
        PagarEstado.parcial => (Colors.blue, 'Parcial'),
        PagarEstado.pagado => (Colors.green, 'Pagada'),
        _ => (Colors.grey, 'Desconocido'),
      };
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return AppScaffold(
      title: 'Cuentas por Pagar',
      body: SafeArea(
        bottom: true,
        child: cuentasAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace? _) => Center(
            child: Padding(
              padding: AppLayout.pantallaPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al cargar cuentas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('$error', textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          data: (List<CuentaPagar> cuentas) {
            if (cuentas.isEmpty) {
              return const Center(
                child: Padding(
                  padding: AppLayout.pantallaPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay cuentas por pagar registradas.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Al confirmar una compra a crédito, aparecerá aquí.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: AppLayout.pantallaPadding,
              itemCount: cuentas.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.m),
              itemBuilder: (BuildContext context, int index) {
                final CuentaPagar cuenta = cuentas[index];
                final bool vencida = cuenta.estaVencida;

                return Card(
                  elevation: vencida ? 2 : 1,
                  color: vencida ? Colors.red.shade50 : null,
                  child: InkWell(
                    onTap: () => context.goNamed(
                      DetalleCuentaPagarPage.routeName,
                      pathParameters: <String, String>{
                        'cuentaId': cuenta.id.toString(),
                      },
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: AppSpacing.allM,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cuenta.nombreProveedor,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      cuenta.numeroDocumento.isNotEmpty
                                          ? cuenta.numeroDocumento
                                          : 'Cuenta #${cuenta.id}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              buildEstadoTag(cuenta),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            runSpacing: 6,
                            children: [
                              Text(
                                'Emisión: ${_formatearFecha(cuenta.fechaEmision)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Vencimiento: ${_formatearFecha(cuenta.fechaVencimiento)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: vencida ? Colors.red.shade700 : null,
                                  fontWeight: vencida ? FontWeight.bold : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total: ${formatRd(cuenta.montoTotal).replaceFirst('RD\$ ', '')}  /*keep*/',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    'Abonado: ${formatRd(cuenta.montoAbonado).replaceFirst('RD\$ ', '')}  /*keep*/',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  Text(
                                    'Pendiente: ${formatRd(cuenta.saldoPendiente).replaceFirst('RD\$ ', '')}  /*keep*/',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: vencida
                                          ? Colors.red.shade700
                                          : Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              if (!esPequena)
                                const Row(
                                  children: [
                                    Text(
                                      'Ver →',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
