import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

final listadoCuentasCobrarProvider = FutureProvider.family<List<CuentaCobrarItem>, int>((
  ref,
  clienteIdFiltro,
) async {
  final db = ref.watch<AppDatabase>(appDatabaseProvider);
  final dao = CuentasCobrarDao(db);
  final registros = await dao.listarCuentasPorCobrar();
  final registrosFiltrados = clienteIdFiltro > 0
      ? registros.where((r) => r.clienteId == clienteIdFiltro).toList()
      : registros;
  final idsClientes = registrosFiltrados.map((r) => r.clienteId).toSet();
  final List<ClientesTableData> registrosClientes = idsClientes.isNotEmpty
      ? await (db.select(db.clientesTable)
            ..where((t) => t.id.isIn(idsClientes)))
          .get()
      : <ClientesTableData>[];
  final mapaClientes = <int, String>{
    for (final row in registrosClientes) row.id: row.nombre,
  };
  return registrosFiltrados.map((reg) {
    final nombreCliente =
        mapaClientes[reg.clienteId] ?? 'Cliente #${reg.clienteId}';
    final estadoTexto = switch (reg.estado) {
      CobrarEstado.pagado => 'Pagado',
      CobrarEstado.vencido => 'Vencido',
      CobrarEstado.parcial => 'Parcial',
      _ => 'Pendiente',
    };
    return CuentaCobrarItem(
      clienteId: reg.clienteId,
      clienteNombre: nombreCliente,
      montoOriginal: reg.montoOriginal,
      montoAbonado: reg.montoAbonado,
      saldoPendiente: reg.saldoPendiente,
      fechaVencimiento: reg.fechaVencimiento,
      estado: estadoTexto,
    );
  }).toList();
});

class CuentaCobrarItem {
  const CuentaCobrarItem({
    required this.clienteId,
    required this.clienteNombre,
    required this.montoOriginal,
    required this.montoAbonado,
    required this.saldoPendiente,
    required this.fechaVencimiento,
    required this.estado,
  });
  final int clienteId;
  final String clienteNombre;
  final double montoOriginal;
  final double montoAbonado;
  final double saldoPendiente;
  final DateTime fechaVencimiento;
  final String estado;
}

class CobrarPage extends ConsumerWidget {
  const CobrarPage({
    super.key,
    this.clienteIdFiltro = 0,
    this.onVolver,
    this.onIrACredito,
  });

  final int clienteIdFiltro;
  final VoidCallback? onVolver;
  final VoidCallback? onIrACredito;

  static const String routeName = 'cobrar';
  static final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');

  Color _colorEstado(String estado) {
    return switch (estado) {
      'Pendiente' => AppColors.warning,
      'Parcial' => AppColors.info,
      'Pagado' => AppColors.success,
      'Vencido' => AppColors.error,
      _ => AppColors.grey500,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentasAsync = ref.watch(listadoCuentasCobrarProvider(clienteIdFiltro));
    final esPantallaPequena = MediaQuery.of(context).size.width < 600;
    final paddingTexto = esPantallaPequena ? 12.0 : 16.0;
    final tamanoCuerpo = esPantallaPequena ? 13.0 : 14.0;
    final tamanoEtiqueta = esPantallaPequena ? 11.0 : 12.0;
    final espaciadoTarjeta = esPantallaPequena ? 8.0 : 12.0;

    return AppScaffold(
      title: clienteIdFiltro > 0
          ? 'Cuentas por Cobrar — Cliente'
          : 'Cuentas por Cobrar',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (onVolver != null) {
            onVolver!();
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
      actions: [
        if (onIrACredito != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: onIrACredito,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('NUEVO CRÉDITO'),
            ),
          ),
      ],
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(listadoCuentasCobrarProvider(clienteIdFiltro));
        },
        child: cuentasAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: EdgeInsets.all(paddingTexto),
              child: Text(
                'Error: $e',
                style: AppTypography.bodyMedium.copyWith(fontSize: tamanoCuerpo),
              ),
            ),
          ),
          data: (cuentas) {
            if (cuentas.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppLayout.pantallaPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        clienteIdFiltro > 0
                            ? 'Este cliente no tiene cuentas por cobrar'
                            : 'No hay cuentas por cobrar',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Al registrar una venta a crédito, aparecerá aquí.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: AppLayout.pantallaPadding,
              itemCount: cuentas.length,
              itemBuilder: (context, i) {
                final c = cuentas[i];
                final vencida = c.estado == 'Vencido';
                return Padding(
                  padding: EdgeInsets.only(bottom: espaciadoTarjeta),
                  child: Container(
                    color: vencida ? AppColors.grey100 : null,
                    padding: EdgeInsets.all(paddingTexto),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.clienteNombre,
                          style: AppTypography.bodyMediumSemiBold,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Total: RD\$ ${c.montoOriginal.toStringAsFixed(2)}',
                          style: AppTypography.bodyMedium.copyWith(fontSize: tamanoCuerpo),
                        ),
                        Text(
                          'Abonado: RD\$ ${c.montoAbonado.toStringAsFixed(2)}',
                          style: AppTypography.bodyMedium.copyWith(fontSize: tamanoCuerpo),
                        ),
                        Text(
                          'Saldo pendiente: RD\$ ${c.saldoPendiente.toStringAsFixed(2)}',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: tamanoCuerpo,
                            fontWeight: FontWeight.w600,
                            color: vencida ? AppColors.error : AppColors.primary,
                          ),
                        ),
                        Text(
                          'Vence: ${_formatoFecha.format(c.fechaVencimiento)}',
                          style: AppTypography.bodyMedium.copyWith(fontSize: tamanoCuerpo),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: _colorEstado(c.estado),
                            borderRadius: AppRadius.allM,
                          ),
                          child: Text(
                            c.estado,
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: tamanoEtiqueta,
                              color: AppColors.white,
                            ),
                          ),
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
    );
  }
}
