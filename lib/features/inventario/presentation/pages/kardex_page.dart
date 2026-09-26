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
    final productoIdConsulta = _productoIdFijo ?? 1;
    final movimientosAsync = ref.watch(kardexPorProductoProvider(productoIdConsulta));

    return AppScaffold(
      // ✅ Barra superior UNIFORME
      title: 'Kárdex',
      subtitle: 'Historial de movimientos de inventario',
      actions: const [],
      floatingActionButton: null,
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 8,
            isMobile ? 12 : 16,
            isMobile ? 16 : 8,
            12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Filtros en fila responsiva
              if (isMobile) ...[
                AppTextField(
                  hint: 'Buscar por producto, documento o fecha...',
                  onChanged: (valor) => setState(() => _filtroBusqueda = valor.trim().toLowerCase()),
                ),
                const SizedBox(height: 12),
                AppDropdown<TipoMovimiento>(
                  initialValue: _filtroTipo,
                  hint: 'Tipo de Movimiento',
                  items: TipoMovimiento.values
                      .map((tipo) => DropdownMenuItem<TipoMovimiento>(
                            value: tipo,
                            child: Text(
                              tipo.name.toUpperCase(),
                              style: AppTypography.bodySmall,
                            ),
                          ))
                      .toList(),
                  onChanged: (valor) => setState(() => _filtroTipo = valor),
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        hint: 'Buscar por producto, documento o fecha...',
                        onChanged: (valor) => setState(() => _filtroBusqueda = valor.trim().toLowerCase()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 220,
                      child: AppDropdown<TipoMovimiento>(
                        initialValue: _filtroTipo,
                        hint: 'Tipo de Movimiento',
                        items: TipoMovimiento.values
                            .map((tipo) => DropdownMenuItem<TipoMovimiento>(
                                  value: tipo,
                                  child: Text(
                                    tipo.name.toUpperCase(),
                                    style: AppTypography.bodySmall,
                                  ),
                                ))
                            .toList(),
                        onChanged: (valor) => setState(() => _filtroTipo = valor),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // Lista de movimientos
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
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
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    error: (error, _) => Center(
                      child: Padding(
                        padding: AppSpacing.allM,
                        child: Text(
                          'Error al cargar movimientos: $error',
                          textAlign: TextAlign.center,
                          style: AppTypography.labelMedium.copyWith(color: AppColors.error),
                        ),
                      ),
                    ),
                    data: (movimientos) {
                      final filtrados = movimientos.where((mov) {
                        if (_productoIdFijo != null && mov.productoId != _productoIdFijo) {
                          return false;
                        }
                        final coincideTexto = mov.productoId.toString().contains(_filtroBusqueda) ||
                            ((mov.documentoReferencia ?? '').toLowerCase().contains(_filtroBusqueda));
                        final coincideTipo = _filtroTipo == null || mov.tipoMovimiento == _filtroTipo;
                        return coincideTexto && coincideTipo;
                      }).toList();

                      if (filtrados.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: AppSpacing.allL,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.history_outlined, size: 48, color: AppColors.grey300),
                                const SizedBox(height: 12),
                                Text(
                                  'No hay movimientos registrados o coincidentes.',
                                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
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
                                color: AppColors.grey50,
                                border: Border(
                                  bottom: BorderSide(color: AppColors.border),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 110,
                                    child: Text(
                                      'TIPO',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'DOCUMENTO / PRODUCTO',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 72,
                                    child: Text(
                                      'CANT.',
                                      textAlign: TextAlign.right,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      'SALDO',
                                      textAlign: TextAlign.right,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      'FECHA',
                                      textAlign: TextAlign.right,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: filtrados.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(color: AppColors.border, height: 1),
                              itemBuilder: (_, indice) {
                                final mov = filtrados[indice];
                                final colorTipo = switch (mov.tipoMovimiento) {
                                  TipoMovimiento.entrada => AppColors.success,
                                  TipoMovimiento.salida => AppColors.error,
                                  TipoMovimiento.ajuste => AppColors.warning,
                                  TipoMovimiento.transferencia => AppColors.info,
                                  _ => AppColors.secondary,
                                };
                                final fechaValida =
                                    mov.fechaMovimiento ?? DateTime.now();
                                final fechaStr =
                                    '${fechaValida.day.toString().padLeft(2, '0')}/'
                                    '${fechaValida.month.toString().padLeft(2, '0')}/'
                                    '${fechaValida.year}';

                                if (isMobile) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: colorTipo,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                mov.tipoMovimiento.name
                                                    .toUpperCase(),
                                                style: AppTypography.labelLarge
                                                    .copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: colorTipo,
                                                ),
                                              ),
                                              Text(
                                                mov.documentoReferencia ??
                                                    'Sin documento',
                                                style: AppTypography.bodySmall
                                                    .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                              Text(
                                                'Cant ${mov.cantidad} · Saldo ${mov.saldoAnterior} → ${mov.saldoNuevo}',
                                                style:
                                                    AppTypography.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          fechaStr,
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                            color: AppColors.textDisabled,
                                          ),
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
                                                    fontWeight: FontWeight.w700,
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
                                          child: Text(
                                            'Prod ${mov.productoId} · ${mov.documentoReferencia ?? 'Sin documento'}',
                                            style: AppTypography.bodySmall,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 72,
                                          child: Text(
                                            '${mov.cantidad}',
                                            textAlign: TextAlign.right,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            '${mov.saldoAnterior} → ${mov.saldoNuevo}',
                                            textAlign: TextAlign.right,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color: AppColors.textSecondary,
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
                                              color: AppColors.textDisabled,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
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
