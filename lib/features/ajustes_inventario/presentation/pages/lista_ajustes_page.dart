import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
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
  @override
  Widget build(BuildContext context) {
    final listaAsync = ref.watch(ajusteInventarioListaProvider);
    final isMobile = AppBreakpoints.isMobile(context);

    return AppScaffold(
      title: 'Lista de Ajustes',
      subtitle: isMobile ? null : 'Correcciones de stock y mermas',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Nuevo Ajuste',
          onPressed: () => context.pushNamed(RegistrarAjustePage.routeName),
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

                    return Container(
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
                      child: Column(
                        children: [
                          if (!isMobile)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8FAFC),
                                border: Border(
                                  bottom: BorderSide(color: AppColors.border),
                                ),
                              ),
                              child: Row(
                                children: [
                                  _h('PRODUCTO', flex: 2),
                                  _h('TIPO', flex: 2),
                                  _h('CANT.', flex: 1, align: TextAlign.right),
                                  _h('MOTIVO', flex: 3),
                                  _h('FECHA', flex: 2, align: TextAlign.right),
                                ],
                              ),
                            ),
                          Expanded(
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: lista.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: AppColors.border,
                              ),
                              itemBuilder: (_, int i) {
                                final AjusteInventario a = lista[i];
                                final fecha =
                                    '${a.fechaCreacion.day.toString().padLeft(2, '0')}/'
                                    '${a.fechaCreacion.month.toString().padLeft(2, '0')}/'
                                    '${a.fechaCreacion.year} '
                                    '${a.fechaCreacion.hour.toString().padLeft(2, '0')}:'
                                    '${a.fechaCreacion.minute.toString().padLeft(2, '0')}';

                                if (isMobile) {
                                  return Padding(
                                    padding: AppSpacing.allM,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Producto ID: ${a.productoId}',
                                          style: AppTypography.labelLarge
                                              .copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${a.tipoAjuste} · Cant. ${a.cantidad}',
                                          style: AppTypography.bodySmall,
                                        ),
                                        Text(
                                          a.motivo,
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                        Text(
                                          fecha,
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                color: AppColors.textDisabled,
                                              ),
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
                                          child: Text(
                                            '${a.productoId}',
                                            style: AppTypography.bodyMedium
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            a.tipoAjuste,
                                            style: AppTypography.bodySmall,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            '${a.cantidad}',
                                            textAlign: TextAlign.right,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            a.motivo,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            fecha,
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
                      ),
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

  static Widget _h(String t, {int flex = 1, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        t,
        textAlign: align,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
