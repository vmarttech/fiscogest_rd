import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_dialog.dart';
import 'package:fiscogest_rd/features/presentaciones/presentation/providers/presentacion_providers.dart';
import 'package:fiscogest_rd/features/presentaciones/domain/entities/presentacion.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

class PresentacionesPage extends ConsumerStatefulWidget {
  const PresentacionesPage({super.key});
  static const String routeName = 'presentaciones';
  @override
  ConsumerState<PresentacionesPage> createState() => _PresentacionesPageState();
}

class _PresentacionesPageState extends ConsumerState<PresentacionesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroBusqueda = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final asyncList = ref.watch(presentacionControllerProvider);

    return AppScaffold(
      title: 'Presentaciones',
      subtitle: 'Administración de presentaciones de productos',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (!isMobile)
          AppButton(
            text: 'Nueva presentación',
            icon: Icons.add,
            onPressed: () => _mostrarModalRegistro(context),
          ),
      ],
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _mostrarModalRegistro(context),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isMobile ? 560 : 920),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 12 : 20,
                isMobile ? 16 : 24,
                isMobile ? 88 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AppTextField(
                      hint: 'Buscar...',
                      prefixIcon: Icons.search,
                      onChanged: (v) =>
                          setState(() => _filtroBusqueda = v.toLowerCase()),
                    ),
                  ),
                  SizedBox(height: isMobile ? 14 : 18),
                  Expanded(
                    child: asyncList.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                      error: (e, _) => Center(
                        child: Text(
                          'Error: $e',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      data: (items) {
                        final filtradas = _filtroBusqueda.isEmpty
                            ? items
                            : items.where((p) => p.nombre.toLowerCase().contains(_filtroBusqueda) || p.abreviatura.toLowerCase().contains(_filtroBusqueda)).toList();

                        if (filtradas.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.straighten,
                                      size: 32,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _filtroBusqueda.isEmpty
                                        ? 'Sin presentaciones aún'
                                        : 'Sin resultados',
                                    style: AppTypography.h4.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _filtroBusqueda.isEmpty
                                        ? 'Crea la primera presentación\n(UND, CAJ, etc.) para tus productos.'
                                        : 'Prueba con otro término de búsqueda.',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                  if (_filtroBusqueda.isEmpty) ...[
                                    const SizedBox(height: 18),
                                    AppButton(
                                      text: 'Nueva presentación',
                                      icon: Icons.add,
                                      onPressed: () =>
                                          _mostrarModalRegistro(context),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }

                        if (isMobile) {
                          return ListView.separated(
                            itemCount: filtradas.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final p = filtradas[i];
                              return _PresentacionCard(
                                item: p,
                                badge: p.abreviatura.isNotEmpty ? p.abreviatura : '—',
                                title: p.nombre,
                                subtitle: 'Abreviatura: ${p.abreviatura}',
                                onEdit: () => _mostrarModalRegistro(
                                  context,
                                  presentacionToEdit: p,
                                ),
                                onDelete: () => _onDelete(context, p),
                              );
                            },
                          );
                        }

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.10),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.04),
                                  border: const Border(
                                    bottom: BorderSide(color: AppColors.border),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 52),
                                    Expanded(
                                      child: Text(
                                        'NOMBRE',
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
                                        'ACCIONES',
                                        textAlign: TextAlign.center,
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
                                  itemCount: filtradas.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    height: 1,
                                    color: AppColors.border,
                                  ),
                                  itemBuilder: (_, i) {
                                    final p = filtradas[i];
                                    return Material(
                                      color: i.isEven
                                          ? Colors.white
                                          : AppColors.grey50.withValues(alpha: 0.55),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  p.abreviatura.isNotEmpty ? p.abreviatura : '—',
                                                  style: AppTypography.labelSmall
                                                      .copyWith(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    p.nombre,
                                                    style: AppTypography.bodyLarge
                                                        .copyWith(
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Abreviatura: ${p.abreviatura}',
                                                    style: AppTypography.bodySmall
                                                        .copyWith(
                                                      color:
                                                          AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  _mostrarModalRegistro(
                                                context,
                                                presentacionToEdit: p,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: AppColors.error,
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  _onDelete(context, p),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  void _onDelete(BuildContext context, Presentacion item) {
    AppDialog.show<void>(
      context,
      title: 'Confirmar Eliminación',
      message: '¿Está seguro de eliminar "${item.nombre}"?',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        AppButton(
          text: 'Eliminar',
          onPressed: () {
            if (item.id != null) {
              ref.read(presentacionControllerProvider.notifier).eliminar(item.id!);
            }
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _mostrarModalRegistro(
    BuildContext context, {
    Presentacion? presentacionToEdit,
  }) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(
      text: presentacionToEdit?.nombre ?? '',
    );
    final abreviaturaController = TextEditingController(
      text: presentacionToEdit?.abreviatura ?? '',
    );
    final isEditing = presentacionToEdit != null;

    AppDialog.show<void>(
      context,
      title: isEditing ? 'Editar Presentación' : 'Nueva Presentación',
      content: SizedBox(
        width: 380,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Nombre de la Presentación',
                controller: nombreController,
              ),
              AppLayout.vM,
              AppTextField(
                label: 'Abreviatura (ej. UND, CAJ)',
                controller: abreviaturaController,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        AppButton(
          text: isEditing ? 'Actualizar' : 'Guardar',
          onPressed: () {
            if (formKey.currentState!.validate()) {
              try {
                final pres = Presentacion(
                  id: presentacionToEdit?.id,
                  nombre: nombreController.text.trim(),
                  abreviatura: abreviaturaController.text.trim().toUpperCase(),
                );
                if (isEditing) {
                  ref
                      .read(presentacionControllerProvider.notifier)
                      .actualizar(pres);
                } else {
                  ref
                      .read(presentacionControllerProvider.notifier)
                      .guardar(pres);
                }
                Navigator.pop(context);
              } catch (e) {
                FiscoGestNotifications.show(
                  SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')),
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }
}


class _PresentacionCard extends StatelessWidget {
  const _PresentacionCard({
    required this.item,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
  });

  final dynamic item;
  final String badge;
  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                badge,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
