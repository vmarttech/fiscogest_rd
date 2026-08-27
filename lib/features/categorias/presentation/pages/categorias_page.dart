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
  static const String routeName = 'categorias';
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
    final esPantallaPequena = MediaQuery.of(context).size.width < 600;
    return AppScaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: AppSpacing.allM,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              esPantallaPequena
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Catalogo de Categorias',
                          style: AppTypography.h2,
                        ),
                        AppLayout.vXs,
                        Text(
                          'Organizacion y clasificacion de productos por categoria.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        AppLayout.vM,
                        AppButton(
                          text: 'Nueva Categoria',
                          icon: Icons.add,
                          onPressed: () => _mostrarModalRegistro(context),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Catalogo de Categorias',
                              style: AppTypography.h2,
                            ),
                            AppLayout.vXs,
                            Text(
                              'Organizacion y clasificacion de productos por categoria.',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        AppButton(
                          text: 'Nueva Categoria',
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
                  hint: 'Buscar categoria por nombre...',
                  prefixIcon: Icons.search,
                  onChanged: (value) => setState(() => _filtroBusqueda = value.toLowerCase()),
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
                        (c.descripcion?.toLowerCase().contains(_filtroBusqueda) ?? false)
                      ).toList();
                      if (filtradas.isEmpty) {
                        return const Center(
                          child: Text(
                            'No hay categorias registradas o coincidentes.',
                            style: AppTypography.bodyMedium,
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: AppSpacing.allS,
                        itemCount: filtradas.length,
                        separatorBuilder: (context, index) => const Divider(color: AppColors.grey200, height: 1),
                        itemBuilder: (context, index) {
                          final categoria = filtradas[index];
                          return Padding(
                            padding: AppSpacing.vS,
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.grey50,
                                    borderRadius: AppRadius.allM,
                                  ),
                                  child: const Icon(Icons.category_outlined, color: AppColors.textPrimary, size: 20),
                                ),
                                AppLayout.hM,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        categoria.nombre,
                                        style: AppTypography.labelLarge,
                                      ),
                                      AppLayout.vXs,
                                      Text(
                                        categoria.descripcion?.isEmpty ?? true ? 'Sin descripcion' : categoria.descripcion!,
                                        style: AppTypography.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                                      tooltip: 'Editar Categoria',
                                      onPressed: () => _mostrarModalRegistro(context, categoriaToEdit: categoria),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                      tooltip: 'Eliminar Categoria',
                                      onPressed: () {
                                        AppDialog.show<void>(
                                          context,
                                          title: 'Confirmar Eliminacion',
                                          message: 'Esta seguro de eliminar la categoria "${categoria.nombre}"?',
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancelar'),
                                            ),
                                            AppButton(
                                              text: 'Eliminar',
                                              onPressed: () {
                                                if (categoria.id != null) {
                                                  ref.read(categoriaControllerProvider.notifier).eliminar(categoria.id!);
                                                }
                                                Navigator.pop(context);
                                              },
                                            ),
                                          ],
                                        );
                                      },
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
                    error: (e, st) => Center(child: Text('Error: $e', style: AppTypography.bodyMedium)),
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
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: categoriaToEdit?.nombre ?? '');
    final descripcionController = TextEditingController(text: categoriaToEdit?.descripcion ?? '');
    final isEditing = categoriaToEdit != null;
    AppDialog.show<void>(
      context,
      title: isEditing ? 'Editar Categoria' : 'Nueva Categoria',
      content: SizedBox(
        width: 380,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Nombre de la Categoria',
                controller: nombreController,
              ),
              AppLayout.vM,
              AppTextField(
                label: 'Descripcion',
                controller: descripcionController,
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
                final cat = Categoria(
                  id: categoriaToEdit?.id,
                  nombre: nombreController.text.trim(),
                  descripcion: descripcionController.text.trim(),
                  creadoEn: categoriaToEdit?.creadoEn ?? DateTime.now(),
                  actualizadoEn: isEditing ? DateTime.now() : null,
                );
                if (isEditing) {
                  ref.read(categoriaControllerProvider.notifier).actualizar(cat);
                } else {
                  ref.read(categoriaControllerProvider.notifier).guardar(cat);
                }
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                );
              }
            }
          },
        ),
      ],
    );
  }
}
