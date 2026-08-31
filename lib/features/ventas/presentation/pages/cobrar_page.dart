import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

class CuentaCobrarItem {
  const CuentaCobrarItem({
    required this.clienteNombre,
    required this.montoOriginal,
    required this.montoAbonado,
    required this.saldoPendiente,
    required this.fechaVencimiento,
    required this.estado,
  });
  final String clienteNombre;
  final double montoOriginal;
  final double montoAbonado;
  final double saldoPendiente;
  final DateTime fechaVencimiento;
  final String estado;
}

final listadoCuentasCobrarProvider = FutureProvider<List<CuentaCobrarItem>>((ref) async {
  final db = ref.watch(databaseProvider);
  final dao = CuentasCobrarDao(db);
  final registros = await dao.listarCuentasPorCobrar();
  return registros.map((reg) {
    final cuenta = reg.cuenta;
    final estadoTexto = switch (cuenta.estado) {
      CobrarEstado.pendiente => 'Pendiente',
      CobrarEstado.vencido => 'Vencido',
      CobrarEstado.pagado => 'Pagado',
      _ => 'Desconocido',
    };
    return CuentaCobrarItem(
      clienteNombre: reg.nombreCliente,
      montoOriginal: cuenta.montoOriginal,
      montoAbonado: cuenta.montoAbonado,
      saldoPendiente: cuenta.saldoPendiente,
      fechaVencimiento: cuenta.fechaVencimiento,
      estado: estadoTexto,
    );
  }).toList();
});

class CobrarPage extends ConsumerStatefulWidget {
  const CobrarPage({super.key});
  static const String routeName = 'cobrar';
  @override
  ConsumerState<CobrarPage> createState() => _CobrarPageState();
}

class _CobrarPageState extends ConsumerState<CobrarPage> {
  @override
  Widget build(BuildContext context) {
    final listado = ref.watch(listadoCuentasCobrarProvider);
    return AppScaffold(
      title: 'Cuentas por Cobrar',
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: AppLayout.pantallaPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestión de Créditos y Cobros',
                      style: AppTypography.h3.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Consulte saldos, registre pagos y administre cuentas pendientes',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: listado.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.warning),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar cuentas: $error',
                          style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  data: (cuentas) {
                    if (cuentas.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payments_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'No hay cuentas por cobrar',
                              style: AppTypography.h3.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Las ventas a crédito aparecerán aquí',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: cuentas.length,
                      itemBuilder: (context, i) {
                        final cta = cuentas[i];
                        final colorEstado = switch (cta.estado) {
                          'Pendiente' => AppColors.info,
                          'Vencido' => AppColors.error,
                          'Pagado' => AppColors.success,
                          _ => AppColors.textSecondary,
                        };
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      cta.clienteNombre,
                                      style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    Chip(
                                      label: Text(cta.estado, style: const TextStyle(fontSize: 12)),
                                      padding: EdgeInsets.zero,
                                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                                      side: BorderSide(color: colorEstado),
                                      backgroundColor: colorEstado.withValues(alpha: 0.08),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Vencimiento: ${cta.fechaVencimiento.day.toString().padLeft(2,'0')}/${cta.fechaVencimiento.month.toString().padLeft(2,'0')}/${cta.fechaVencimiento.year}'),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Original: \$${cta.montoOriginal.toStringAsFixed(2)}'),
                                    Text('Abonado: \$${cta.montoAbonado.toStringAsFixed(2)}'),
                                    Text(
                                      'Pendiente: \$${cta.saldoPendiente.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
