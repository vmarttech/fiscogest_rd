import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/cuenta_pagar.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/abono.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/cuentas_pagar_providers.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/cuentas_pagar/registrar_abono_page.dart';

class DetalleCuentaPagarPage extends ConsumerStatefulWidget {
  const DetalleCuentaPagarPage({super.key, required this.cuentaId});
  static const String routeName = 'detalle-cuenta-pagar';
  final Object cuentaId;

  @override
  ConsumerState<DetalleCuentaPagarPage> createState() => _DetalleCuentaPagarPageState();
}

class _DetalleCuentaPagarPageState extends ConsumerState<DetalleCuentaPagarPage> {
  late final int _idNumerico;

  @override
  void initState() {
    super.initState();
    _idNumerico = switch (widget.cuentaId) {
      final int id => id,
      final String idStr => int.tryParse(idStr) ?? 0,
      _ => 0,
    };
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '—';
    return fecha.toString().split(' ')[0];
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<CuentaPagar?> cuentaAsync = ref.watch(cuentaPagarPorIdProvider(_idNumerico));
    final AsyncValue<List<Abono>> abonosAsync = ref.watch(historialAbonosProvider(_idNumerico));
    final double ancho = MediaQuery.of(context).size.width;
    final bool esPequena = ancho < 768;

    return AppScaffold(
      title: 'Detalle de Cuenta',
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: AppLayout.pantallaPadding,
          child: cuentaAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace? _) => Center(
              child: Padding(
                padding: AppSpacing.allM,
                child: Text(
                  'Error al cargar cuenta: $error',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMedium.copyWith(color: AppColors.error),
                ),
              ),
            ),
            data: (CuentaPagar? cuenta) {
              if (cuenta == null) {
                return const Center(
                  child: Padding(
                    padding: AppSpacing.allL,
                    child: Text(
                      'Cuenta no encontrada.',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                );
              }

              final bool vencida = cuenta.estaVencida;
              final double saldoPendiente = cuenta.saldoPendiente;
              final bool puedeAbonar = saldoPendiente > 0;

              Widget buildEstadoTag() {
                final (Color color, String texto) = switch (cuenta.estado) {
                  PagarEstado.pendiente when vencida => (Colors.red, 'Vencida'),
                  PagarEstado.pendiente => (Colors.orange, 'Pendiente'),
                  PagarEstado.parcial => (Colors.blue, 'Parcial'),
                  PagarEstado.pagado => (Colors.green, 'Pagada'),
                  _ => (Colors.grey, 'Desconocido'),
                };
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    texto,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          cuenta.nombreProveedor,
                          style: AppTypography.h4Bold,
                        ),
                      ),
                      buildEstadoTag(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (vencida)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Row(
                        children: <Widget>[
                          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Esta cuenta está vencida.',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: <Widget>[
                      Text(
                        'Documento: ${cuenta.numeroDocumento}',
                        style: AppTypography.bodyMedium,
                      ),
                      Text(
                        'Emisión: ${_formatearFecha(cuenta.fechaEmision)}',
                        style: AppTypography.bodySmall,
                      ),
                      Text(
                        'Vencimiento: ${_formatearFecha(cuenta.fechaVencimiento)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: vencida ? Colors.red.shade700 : null,
                          fontWeight: vencida ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    child: Padding(
                      padding: AppSpacing.allM,
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              const Text('Monto Total:', style: AppTypography.bodyMedium),
                              Text(formatRd(cuenta.montoTotal), style: AppTypography.bodyMediumBold),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              const Text('Total Abonado:', style: AppTypography.bodyMedium),
                              Text(
                                formatRd(cuenta.montoAbonado),
                                style: AppTypography.bodyMediumBold.copyWith(color: Colors.green.shade700),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                'Saldo Pendiente:',
                                style: AppTypography.bodyMediumSemiBold.copyWith(
                                  color: vencida ? Colors.red.shade700 : AppColors.primary,
                                ),
                              ),
                              Text(
                                formatRd(saldoPendiente),
                                style: AppTypography.h4Bold.copyWith(
                                  color: vencida ? Colors.red.shade700 : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Historial de Abonos',
                    style: AppTypography.labelLarge,
                  ),
                  const SizedBox(height: 12),
                  abonosAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (Object error, StackTrace? _) => Padding(
                      padding: AppSpacing.allM,
                      child: Text(
                        'No se pudo cargar el historial: $error',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                      ),
                    ),
                    data: (List<Abono> abonos) {
                      if (abonos.isEmpty) {
                        return const Padding(
                          padding: AppSpacing.allL,
                          child: Text(
                            'Sin abonos registrados.',
                            style: AppTypography.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return Column(
                        children: abonos.map((Abono abono) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Padding(
                              padding: AppSpacing.allM,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        _formatearFecha(abono.fecha),
                                        style: AppTypography.bodyMediumSemiBold,
                                      ),
                                      Text(
                                        abono.formaPago,
                                        style: AppTypography.bodySmall,
                                      ),
                                      if (abono.referencia.isNotEmpty)
                                        Text(
                                          'Ref: ${abono.referencia}',
                                          style: AppTypography.bodySmall,
                                        ),
                                    ],
                                  ),
                                  Text(
                                    formatRd(abono.monto),
                                    style: AppTypography.bodyMediumBold.copyWith(
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      TextButton.icon(
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Volver'),
                        onPressed: () => context.pop(),
                      ),
                      if (!esPequena && puedeAbonar)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.payment, size: 18),
                          label: const Text('Registrar Abono'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => context.goNamed(
                            RegistrarAbonoPage.routeName,
                            pathParameters: <String, String>{'cuentaId': _idNumerico.toString()},
                          ),
                        ),
                    ],
                  ),
                  if (esPequena && puedeAbonar) ...<Widget>[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.payment, size: 18),
                        label: const Text('Registrar Abono'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => context.goNamed(
                          RegistrarAbonoPage.routeName,
                          pathParameters: <String, String>{'cuentaId': _idNumerico.toString()},
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
