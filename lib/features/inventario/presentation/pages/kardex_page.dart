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
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_hub_hero.dart';

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
    final isMobile = AppBreakpoints.isMobile(context);
    final movimientosAsync = _productoIdFijo != null
        ? ref.watch(kardexPorProductoProvider(_productoIdFijo))
        : ref.watch(kardexHistorialCompletoProvider);

    return AppScaffold(
      // ✅ Barra superior UNIFORME
      title: 'KÁRDEX',

      actions: const [],
      floatingActionButton: null,
      body: SafeArea(
        bottom: true,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: AppLayout.pantallaPadding.add(
                const EdgeInsets.only(bottom: 12),
              ),
              child: ListView(
                children: [
                  const AppHubHero(
                    title: 'Kárdex de inventario',
                    subtitle:
                        'Entradas, salidas y saldos por producto y documento.',
                    icon: Icons.history_edu_rounded,
                  ),
                  SizedBox(height: isMobile ? 14 : 18),
                  Align(
                    alignment: isMobile
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      padding: EdgeInsets.all(isMobile ? 8 : 14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: isMobile
                            ? CrossAxisAlignment.stretch
                            : CrossAxisAlignment.start,
                        children: [
                          // En móvil, los filtros comparten una sola fila para
                          // dejar más altura disponible al historial.
                          if (isMobile) ...[
                            SizedBox(
                              width: double.infinity,
                              child: AppTextField(
                                height: 48,
                                prefixIcon: Icons.search_rounded,
                                hint: 'Producto o documento',
                                onChanged: (valor) => setState(
                                  () => _filtroBusqueda = valor
                                      .trim()
                                      .toLowerCase(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: 200,
                                child: AppDropdown<TipoMovimiento>(
                                  initialValue: _filtroTipo,
                                  hint: 'Tipo',
                                  items: TipoMovimiento.values
                                      .map(
                                        (
                                          tipo,
                                        ) => DropdownMenuItem<TipoMovimiento>(
                                          value: tipo,
                                          child: Text(
                                            switch (tipo) {
                                              TipoMovimiento.transferencia =>
                                                'TRANSFER.',
                                              TipoMovimiento.devolucion =>
                                                'DEVOLUCIÓN',
                                              _ => tipo.name.toUpperCase(),
                                            },
                                            style: AppTypography.bodySmall
                                                .copyWith(fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (valor) =>
                                      setState(() => _filtroTipo = valor),
                                ),
                              ),
                            ),
                          ] else
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 460,
                                  child: AppTextField(
                                    height: 48,
                                    prefixIcon: Icons.search_rounded,
                                    hint: 'Buscar producto o documento',
                                    onChanged: (valor) => setState(
                                      () => _filtroBusqueda = valor
                                          .trim()
                                          .toLowerCase(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 220,
                                  child: AppDropdown<TipoMovimiento>(
                                    initialValue: _filtroTipo,
                                    hint: 'Tipo de Movimiento',
                                    items: TipoMovimiento.values
                                        .map(
                                          (tipo) =>
                                              DropdownMenuItem<TipoMovimiento>(
                                                value: tipo,
                                                child: Text(
                                                  tipo.name.toUpperCase(),
                                                  style:
                                                      AppTypography.bodySmall,
                                                ),
                                              ),
                                        )
                                        .toList(),
                                    onChanged: (valor) =>
                                        setState(() => _filtroTipo = valor),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Lista de movimientos
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.grey900.withValues(alpha: 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: movimientosAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                      error: (error, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
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
                              mov.productoId.toString().contains(
                                _filtroBusqueda,
                              ) ||
                              ((mov.documentoReferencia ?? '')
                                  .toLowerCase()
                                  .contains(_filtroBusqueda));
                          final coincideTipo =
                              _filtroTipo == null ||
                              mov.tipoMovimiento == _filtroTipo;
                          return coincideTexto && coincideTipo;
                        }).toList();

                        if (filtrados.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Padding(
                              padding: AppSpacing.allL,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.history_outlined,
                                    size: 48,
                                    color: AppColors.grey300,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No hay movimientos registrados o coincidentes.',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: [
                            // Cabecera tipo tabla (desktop)
                            if (!isMobile)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.white,
                                  border: Border(
                                    bottom: BorderSide(color: AppColors.border),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 110,
                                      child: _kardexHeaderCell(
                                        'TIPO',
                                        AppColors.primary,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: _kardexHeaderCell(
                                        'DOCUMENTO',
                                        AppColors.info,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 72,
                                      child: _kardexHeaderCell(
                                        'CANT.',
                                        AppColors.warning,
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 120,
                                      child: _kardexHeaderCell(
                                        'SALDO',
                                        AppColors.success,
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 100,
                                      child: _kardexHeaderCell(
                                        'FECHA',
                                        AppColors.secondary,
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            ListView.separated(
                              shrinkWrap: true,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: filtrados.length,
                              separatorBuilder: (_, __) => isMobile
                                  ? const SizedBox.shrink()
                                  : Divider(
                                      color: AppColors.border.withValues(
                                        alpha: 0.9,
                                      ),
                                      height: 1,
                                      thickness: 1,
                                    ),
                              itemBuilder: (_, indice) {
                                final mov = filtrados[indice];
                                final colorTipo = switch (mov.tipoMovimiento) {
                                  TipoMovimiento.entrada => AppColors.success,
                                  TipoMovimiento.salida => AppColors.error,
                                  TipoMovimiento.ajuste => AppColors.warning,
                                  TipoMovimiento.transferencia =>
                                    AppColors.info,
                                  _ => AppColors.secondary,
                                };
                                final fechaValida =
                                    mov.fechaMovimiento ?? DateTime.now();
                                final fechaStr =
                                    '${fechaValida.day.toString().padLeft(2, '0')}/'
                                    '${fechaValida.month.toString().padLeft(2, '0')}/'
                                    '${fechaValida.year}';

                                if (isMobile) {
                                  final cantStr =
                                      mov.cantidad ==
                                          mov.cantidad.roundToDouble()
                                      ? mov.cantidad.toInt().toString()
                                      : mov.cantidad.toStringAsFixed(1);
                                  final sa = mov.saldoAnterior;
                                  final sn = mov.saldoNuevo;
                                  final saldoStr =
                                      '${sa == sa.roundToDouble() ? sa.toInt() : sa.toStringAsFixed(1)} → ${sn == sn.roundToDouble() ? sn.toInt() : sn.toStringAsFixed(1)}';
                                  final doc = (mov.documentoReferencia ?? '')
                                      .trim();
                                  return Container(
                                    margin: const EdgeInsets.fromLTRB(
                                      10,
                                      6,
                                      10,
                                      6,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 4,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: colorTipo,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                mov.tipoMovimiento.name
                                                    .toUpperCase(),
                                                style: AppTypography.labelLarge
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: colorTipo,
                                                    ),
                                              ),
                                            ),
                                            Text(
                                              fechaStr,
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                    color: AppColors.textPrimary
                                                        .withValues(
                                                          alpha: 0.75,
                                                        ),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          doc.isEmpty ? 'Sin documento' : doc,
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Producto #${mov.productoId}',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                color: AppColors.textPrimary
                                                    .withValues(alpha: 0.65),
                                              ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Cant. $cantStr',
                                                style: AppTypography.bodyMedium
                                                    .copyWith(
                                                      color:
                                                          AppColors.textPrimary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                            Text(
                                              'Saldo $saldoStr',
                                              style: AppTypography.bodyMedium
                                                  .copyWith(
                                                    color: AppColors.textPrimary
                                                        .withValues(
                                                          alpha: 0.85,
                                                        ),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                // Desktop: fila densa en columnas
                                return Material(
                                  color: indice.isEven
                                      ? AppColors.white
                                      : AppColors.grey50.withValues(alpha: 0.5),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 110,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 4,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: colorTipo,
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  mov.tipoMovimiento.name
                                                      .toUpperCase(),
                                                  style: AppTypography
                                                      .labelMedium
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: colorTipo,
                                                      ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (mov.documentoReferencia ?? '')
                                                        .trim()
                                                        .isEmpty
                                                    ? 'Sin documento'
                                                    : mov.documentoReferencia!
                                                          .trim(),
                                                style: AppTypography.bodyMedium
                                                    .copyWith(
                                                      color:
                                                          AppColors.textPrimary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'Producto #${mov.productoId}',
                                                style: AppTypography.bodySmall
                                                    .copyWith(
                                                      color: AppColors
                                                          .textPrimary
                                                          .withValues(
                                                            alpha: 0.65,
                                                          ),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: 72,
                                          child: Text(
                                            '${mov.cantidad}',
                                            textAlign: TextAlign.right,
                                            style: AppTypography.bodyMedium
                                                .copyWith(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: colorTipo.withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${mov.saldoAnterior} → ${mov.saldoNuevo}',
                                                textAlign: TextAlign.right,
                                                style: AppTypography.bodySmall
                                                    .copyWith(
                                                      color: colorTipo,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            fechaStr,
                                            textAlign: TextAlign.right,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
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

Widget _kardexHeaderCell(
  String label,
  Color color, {
  TextAlign textAlign = TextAlign.left,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.11),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.24)),
    ),
    child: Text(
      label,
      textAlign: textAlign,
      style: AppTypography.labelSmall.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        fontSize: 11,
      ),
    ),
  );
}
