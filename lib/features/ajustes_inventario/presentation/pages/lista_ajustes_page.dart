import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/presentation/providers/ajuste_inventario_provider.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/presentation/pages/registrar_ajuste_page.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/ajuste_inventario.dart';

class ListaAjustesPage extends ConsumerStatefulWidget {
  const ListaAjustesPage({super.key});
  static const String routeName = 'lista-ajustes';

  @override
  ConsumerState<ListaAjustesPage> createState() => _ListaAjustesPageState();
}

class _ListaAjustesPageState extends ConsumerState<ListaAjustesPage> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final listaAsync = ref.watch(ajusteInventarioListaProvider);
    final isMobile = AppBreakpoints.isMobile(context);

    return AppScaffold(
      title: 'Lista de Ajustes',
      subtitle: isMobile ? null : 'Correcciones de stock y mermas',
      actions: [
        if (isMobile)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Tooltip(
              message: 'Nuevo ajuste',
              child: SizedBox(
                width: 44,
                height: 42,
                child: FilledButton(
                  onPressed: () =>
                      context.pushNamed(RegistrarAjustePage.routeName),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.add_rounded, size: 25),
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: () => context.pushNamed(RegistrarAjustePage.routeName),
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Nuevo ajuste'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 8,
            isMobile ? 12 : 16,
            isMobile ? 16 : 8,
            12,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () =>
                    ref.refresh(ajusteInventarioListaProvider.future),
                child: listaAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (Object e, _) => Center(
                    child: Text(
                      'Error: $e',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  data: (List<AjusteInventario> lista) {
                    final maxTableHeight =
                        (MediaQuery.sizeOf(context).height - 220).clamp(
                          240.0,
                          560.0,
                        );
                    final filtrada = lista.where((ajuste) {
                      final consulta = _busqueda.trim().toLowerCase();
                      return consulta.isEmpty ||
                          ajuste.productoId.toString().contains(consulta) ||
                          (ajuste.codigoBusqueda ?? '').toLowerCase().contains(
                            consulta,
                          ) ||
                          ajuste.tipoAjuste.toLowerCase().contains(consulta) ||
                          ajuste.motivo.toLowerCase().contains(consulta);
                    }).toList();

                    if (lista.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          const Icon(
                            Icons.tune_outlined,
                            size: 48,
                            color: AppColors.grey300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No hay ajustes registrados',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.grey900.withValues(
                                    alpha: 0.04,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: isMobile ? double.infinity : 460,
                              child: AppTextField(
                                height: 48,
                                prefixIcon: Icons.search_rounded,
                                hint: 'Buscar producto, tipo o motivo...',
                                onChanged: (valor) =>
                                    setState(() => _busqueda = valor),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (filtrada.isEmpty)
                          SizedBox(
                            height: 160,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 52),
                                Text(
                                  'No hay ajustes que coincidan con la búsqueda.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            height:
                                (filtrada.length * (isMobile ? 124 : 76) +
                                        (isMobile ? 12 : 58))
                                    .clamp(
                                      isMobile ? 160.0 : 132.0,
                                      maxTableHeight,
                                    )
                                    .toDouble(),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.grey900.withValues(
                                      alpha: 0.05,
                                    ),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  if (!isMobile)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 11,
                                      ),
                                      decoration: const BoxDecoration(
                                        color: AppColors.white,
                                        border: Border(
                                          bottom: BorderSide(
                                            color: AppColors.border,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          _h(
                                            'PRODUCTO',
                                            flex: 2,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          _h(
                                            'TIPO',
                                            flex: 2,
                                            color: AppColors.info,
                                          ),
                                          const SizedBox(width: 8),
                                          _h(
                                            'CANT.',
                                            flex: 1,
                                            align: TextAlign.right,
                                            color: AppColors.warning,
                                          ),
                                          const SizedBox(width: 8),
                                          _h(
                                            'MOTIVO',
                                            flex: 3,
                                            color: AppColors.secondary,
                                          ),
                                          const SizedBox(width: 8),
                                          _h(
                                            'FECHA',
                                            flex: 2,
                                            align: TextAlign.right,
                                            color: AppColors.success,
                                          ),
                                        ],
                                      ),
                                    ),
                                  Expanded(
                                    child: ListView.separated(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      itemCount: filtrada.length,
                                      separatorBuilder: (_, __) => isMobile
                                          ? const SizedBox(height: 10)
                                          : const Divider(
                                              height: 1,
                                              color: AppColors.border,
                                            ),
                                      itemBuilder: (_, int i) {
                                        final AjusteInventario a = filtrada[i];
                                        final colorTipo =
                                            a.tipoAjuste.toLowerCase() ==
                                                'salida'
                                            ? AppColors.error
                                            : AppColors.success;
                                        final fecha =
                                            '${a.fechaCreacion.day.toString().padLeft(2, '0')}/'
                                            '${a.fechaCreacion.month.toString().padLeft(2, '0')}/'
                                            '${a.fechaCreacion.year} '
                                            '${a.fechaCreacion.hour.toString().padLeft(2, '0')}:'
                                            '${a.fechaCreacion.minute.toString().padLeft(2, '0')}';

                                        if (isMobile) {
                                          return Container(
                                            padding: AppSpacing.allM,
                                            decoration: BoxDecoration(
                                              color: AppColors.white,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: AppColors.border,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Producto ID: ${a.productoId}',
                                                  style: AppTypography
                                                      .labelLarge
                                                      .copyWith(
                                                        color: AppColors
                                                            .textPrimary,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                                const SizedBox(height: 10),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    _datoBadge(
                                                      a.tipoAjuste
                                                          .toUpperCase(),
                                                      colorTipo,
                                                    ),
                                                    _datoBadge(
                                                      'Cantidad ${a.cantidad}',
                                                      colorTipo,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.all(
                                                    10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.grey100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Motivo: ${a.motivo}',
                                                    style: AppTypography
                                                        .bodySmall
                                                        .copyWith(
                                                          color:
                                                              AppColors.grey700,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.schedule_rounded,
                                                      size: 16,
                                                      color: AppColors.grey600,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      fecha,
                                                      style: AppTypography
                                                          .bodySmall
                                                          .copyWith(
                                                            color: AppColors
                                                                .textPrimary,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        return Material(
                                          color: i.isEven
                                              ? AppColors.white
                                              : AppColors.grey50.withValues(
                                                  alpha: 0.55,
                                                ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
                                                    child: Text(
                                                      '${a.productoId}',
                                                      style: AppTypography
                                                          .bodyMedium
                                                          .copyWith(
                                                            color: AppColors
                                                                .textPrimary,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  flex: 2,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
                                                    child: Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 6,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: colorTipo
                                                              .withValues(
                                                                alpha: 0.12,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          a.tipoAjuste,
                                                          style: AppTypography
                                                              .bodySmall
                                                              .copyWith(
                                                                color:
                                                                    colorTipo,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  flex: 1,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
                                                    child: Align(
                                                      alignment:
                                                          Alignment.centerRight,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 6,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: colorTipo
                                                              .withValues(
                                                                alpha: 0.12,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          '${a.cantidad}',
                                                          textAlign:
                                                              TextAlign.right,
                                                          style: AppTypography
                                                              .bodyMedium
                                                              .copyWith(
                                                                color:
                                                                    colorTipo,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  flex: 3,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            AppColors.grey100,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        a.motivo,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: AppTypography
                                                            .bodySmall
                                                            .copyWith(
                                                              color: AppColors
                                                                  .grey700,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  flex: 2,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
                                                    child: Text(
                                                      fecha,
                                                      textAlign:
                                                          TextAlign.right,
                                                      style: AppTypography
                                                          .bodySmall
                                                          .copyWith(
                                                            color: AppColors
                                                                .textPrimary,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
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
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _h(
    String t, {
    int flex = 1,
    TextAlign align = TextAlign.left,
    required Color color,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Text(
          t,
          textAlign: align,
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  static Widget _datoBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
