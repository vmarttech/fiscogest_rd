import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_dialog.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/categoria_providers.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/categoria.dart';

class CategoriasPage extends ConsumerStatefulWidget {
  const CategoriasPage({super.key});

  @override
  ConsumerState<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends ConsumerState<CategoriasPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroBusqueda = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(categoriaControllerProvider);

    return AppScaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: AppSpacing.allM,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Catálogo de Categorías', style: AppTypography.h2),
                      AppLayout.vXs,
                      Text(
                        'Organización y clasificación de productos por categoría.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  AppButton(
                    text: 'Nueva Categoría',
                    icon: Icons.add,
                    onPressed: () => _mostrarModalRegistro(context),
                  ),
                ],
              ),
              AppLayout.vM,
              AppCard(
                padding: AppSpacing.hM.copyWith(top: AppSpacing.s, bottom: AppSpacing.s),
                child: AppTextField(
                  controller: _searchController,
                  hint: 'Buscar categoría por nombre...',
                  prefixIcon: Icons.search,
                  onChanged: (String value) => setState(() => _filtroBusqueda = value.toLowerCase()),
                ),
              ),
              AppLayout.vM,
              Expanded(
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: categoriasAsync.when(
                    data: (categorias) {
                      final filtradas = categorias.where((c) =>
                        c.nombre.toLowerCase().contains(_filtroBusqueda) ||
                        ((c.descripcion ?? '').toLowerCase().contains(_filtroBusqueda))
                      ).toList();

                      if (filtradas.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: AppSpacing.allL,
                            child: Text(
                              'No hay categorías registradas o coincidentes.',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: AppSpacing.allS,
                        itemCount: filtradas.length,
                        separatorBuilder: (_, __) => const Divider(color: AppColors.grey200, height: 1),
                        itemBuilder: (_, i) {
                          final categoria = filtradas[i];
                          return Padding(
                            padding: AppSpacing.vS,
                            child: Row(
                              children: [
                                Container(
                                  width: 42, height: 42,
                                  decoration: BoxDecoration(color: AppColors.grey50, borderRadius: AppRadius.allM),
                                  child: const Icon(Icons.category_outlined, color: AppColors.textPrimary, size: 20),
                                ),
                                AppLayout.hM,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(categoria.nombre, style: AppTypography.labelLarge),
                                      AppLayout.vXs,
                                      Text(
                                        (categoria.descripcion?.trim().isEmpty ?? true) ? 'Sin descripción' : categoria.descripcion,
                                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                                      tooltip: 'Editar Categoría',
                                      onPressed: () => _mostrarModalRegistro(context, categoriaToEdit: categoria),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                      tooltip: 'Eliminar Categoría',
                                      onPressed: () => AppDialog.show<void>(
                                        context,
                                        title: 'Confirmar Eliminación',
                                        message: '¿Está seguro de eliminar la categoría "${categoria.nombre}"?',
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                                          AppButton(
                                            text: 'Eliminar',
                                            onPressed: () {
                                              if (categoria.id != null) ref.read(categoriaControllerProvider.notifier).eliminar(categoria.id!);
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: AppSpacing.allM,
                        child: Text(
                          'Error al cargar categorías: $e',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarModalRegistro(BuildContext context, {Categoria? categoriaToEdit}) {
    final nombreCtrl = TextEditingController(text: categoriaToEdit?.nombre ?? '');
    final descCtrl = TextEditingController(text: categoriaToEdit?.descripcion ?? '');
    final isEdit = categoriaToEdit != null;

    AppDialog.show<void>(
      context,
      title: isEdit ? 'Editar Categoría' : 'Nueva Categoría',
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: 'Nombre de la Categoría', controller: nombreCtrl),
            AppLayout.vM,
            AppTextField(label: 'Descripción', controller: descCtrl),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        AppButton(
          text: isEdit ? 'Actualizar' : 'Guardar',
          onPressed: () {
            if (nombreCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese un nombre de categoría')));
              return;
            }
            try {
              final cat = Categoria(
                id: categoriaToEdit?.id,
                nombre: nombreCtrl.text.trim(),
                descripcion: descCtrl.text.trim(),
                creadoEn: categoriaToEdit?.creadoEn ?? DateTime.now(),
                actualizadoEn: isEdit ? DateTime.now() : null,
              );
              isEdit
                ? ref.read(categoriaControllerProvider.notifier).actualizar(cat)
                : ref.read(categoriaControllerProvider.notifier).guardar(cat);
              Navigator.pop(context);
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
            }
          },
        ),
      ],
    );
  }
}
