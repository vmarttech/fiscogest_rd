import 'package:fiscogest_rd/features/inventario_fisico/presentation/pages/capturar_conteo_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/providers/inventario_fisico_provider.dart';

class ListarConteosPage extends ConsumerWidget {
  const ListarConteosPage({super.key});
  static const routeName = 'lista-conteos-fisicos';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conteosAsync = ref.watch(listaConteosProvider);
    final isMobile = AppBreakpoints.isMobile(context);

    return AppScaffold(
      title: 'Inventario Físico',
      subtitle: isMobile ? null : 'Conteos y diferencias de stock',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Nuevo Conteo',
          onPressed: () => context.pushNamed('registrar-conteo-fisico'),
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
              child: conteosAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Error: $e',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.error),
                  ),
                ),
                data: (lista) {
                  if (lista.isEmpty) {
                    return Center(
                      child: Text(
                        'No hay conteos registrados. Cree el primero.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
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
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'CONTEO',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'FECHA',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'ESTADO',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 32),
                              ],
                            ),
                          ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: lista.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: AppColors.border,
                            ),
                            itemBuilder: (_, i) {
                              final c = lista[i];
                              final fecha =
                                  '${c.fechaConteo.day.toString().padLeft(2, '0')}/'
                                  '${c.fechaConteo.month.toString().padLeft(2, '0')}/'
                                  '${c.fechaConteo.year}';
                              final estado = c.estado.etiqueta;

                              return Material(
                                color: i.isEven
                                    ? AppColors.white
                                    : AppColors.grey50.withValues(alpha: 0.55),
                                child: InkWell(
                                  onTap: () => context.pushNamed(
                                    CapturarConteoPage.routeName,
                                    pathParameters: {
                                      'conteoId': '${c.id ?? 0}',
                                    },
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: isMobile
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                c.nombreConteo,
                                                style: AppTypography.labelLarge
                                                    .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Fecha: $fecha · Estado: $estado',
                                                style: AppTypography.bodySmall
                                                    .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: Text(
                                                  c.nombreConteo,
                                                  style: AppTypography
                                                      .bodyMedium
                                                      .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  fecha,
                                                  style:
                                                      AppTypography.bodySmall,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  estado,
                                                  style: AppTypography.bodySmall
                                                      .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const Icon(
                                                Icons.chevron_right,
                                                size: 20,
                                                color: AppColors.grey400,
                                              ),
                                            ],
                                          ),
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
    );
  }
}
