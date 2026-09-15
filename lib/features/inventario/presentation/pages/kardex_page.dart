import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/kardex_provider.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_dropdown.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';

class KardexPage extends ConsumerStatefulWidget {
  const KardexPage({super.key, this.productoId});
  static const String routeName = 'kardex';
  final String? productoId;

  @override
  ConsumerState<KardexPage> createState() => _KardexPageState();
}

class _KardexPageState extends ConsumerState<KardexPage> {
  late final int? _productoIdFijo;
  String _filtroBusqueda = '';
  TipoMovimiento? _filtroTipo;

  @override
  void initState() {
    super.initState();
    _productoIdFijo = widget.productoId != null
        ? int.tryParse(widget.productoId!.replaceAll(RegExp(r'[^0-9]'), ''))
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final productoIdConsulta = _productoIdFijo ?? 1;
    final movimientosAsync = ref.watch(kardexPorProductoProvider(productoIdConsulta));

    return AppScaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: AppLayout.pantallaPadding,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveRow(
                    child1: AppTextField(
                      hint: 'Buscar por producto, documento o fecha...',
                      onChanged: (valor) => setState(
                        () => _filtroBusqueda = valor.trim().toLowerCase(),
                      ),
                    ),
                    child2: AppDropdown<TipoMovimiento>(
                      initialValue: _filtroTipo,
                      hint: 'Tipo de Movimiento',
                      items: TipoMovimiento.values
                          .map(
                            (tipo) => DropdownMenuItem<TipoMovimiento>(
                              value: tipo,
                              child: Text(
                                tipo.name.toUpperCase(),
                                style: AppTypography.bodySmall,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (valor) => setState(() => _filtroTipo = valor),
                    ),
                  ),
                  AppLayout.vM,
                  SizedBox(
                    height: MediaQuery.of(context).size.height - 320,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: movimientosAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, pila) => Center(
                          child: Padding(
                            padding: AppSpacing.allM,
                            child: Text(
                              'Error al cargar movimientos: $error',
                              textAlign: TextAlign.center,
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ),
                        data: (movimientos) {
                          final filtrados = movimientos.where((mov) {
                            if (_productoIdFijo != null &&
                                mov.productoId != _productoIdFijo) {
                              return false;
                            }
                            final coincideTexto =
                                mov.productoId.toString().contains(_filtroBusqueda) ||
                                ((mov.documentoReferencia ?? '').toLowerCase().contains(_filtroBusqueda));
                            final coincideTipo =
                                _filtroTipo == null ||
                                mov.tipoMovimiento == _filtroTipo;
                            return coincideTexto && coincideTipo;
                          }).toList();

                          if (filtrados.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: AppSpacing.allL,
                                child: Text(
                                  'No hay movimientos registrados o coincidentes.',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: AppSpacing.allS,
                            itemCount: filtrados.length,
                            separatorBuilder: (_, __) => const Divider(
                              color: AppColors.border,
                              height: 1,
                            ),
                            itemBuilder: (_, indice) {
                              final mov = filtrados[indice];
                              final colorTipo = switch (mov.tipoMovimiento) {
                                TipoMovimiento.entrada => AppColors.success,
                                TipoMovimiento.salida => AppColors.error,
                                TipoMovimiento.ajuste => AppColors.warning,
                                TipoMovimiento.transferencia => AppColors.info,
                                _ => AppColors.secondary,
                              };
                              final fechaValida = mov.fechaMovimiento ?? DateTime.now();
                              return Padding(
                                padding: AppSpacing.vS,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: colorTipo,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.m),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mov.tipoMovimiento.name.toUpperCase(),
                                            style: AppTypography.labelLarge
                                                .copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          AppLayout.vXs,
                                          Text(
                                            'Prod: ${mov.productoId} • Doc: ${mov.documentoReferencia ?? 'Sin documento'}',
                                            style: AppTypography.bodySmall
                                                .copyWith(color: AppColors.textSecondary),
                                          ),
                                          Text(
                                            'Cant: ${mov.cantidad} • Saldo: ${mov.saldoAnterior} → ${mov.saldoNuevo}',
                                            style: AppTypography.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${fechaValida.day.toString().padLeft(2, '0')}/'
                                      '${fechaValida.month.toString().padLeft(2, '0')}/'
                                      '${fechaValida.year}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textDisabled,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
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
