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
  String _filtroBusqueda = '';

  void _mostrarBusqueda(BuildContext context) async {
    final control = TextEditingController(text: _filtroBusqueda);
    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buscar Categoría'),
        content: AppTextField(controller: control, hint: 'Nombre de la categoría...'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          AppButton(text: 'Buscar', onPressed: () => Navigator.pop(ctx, control.text)),
        ],
      ),
    );
    if (resultado != null) {
      setState(() => _filtroBusqueda = resultado.toLowerCase());
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(categoriaControllerProvider);
    return AppScaffold(
      
      padding: AppSpacing.hL.copyWith(top: AppSpacing.m, bottom: AppSpacing.l),
      body: Stack(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: categoriasAsync.when(
                data: (categorias) {
                  final filtradas = _filtroBusqueda.isEmpty
                      ? categorias
                      : categorias.where((c) =>
                          c.nombre.toLowerCase().contains(_filtroBusqueda) ||
                          (c.descripcion?.toLowerCase().contains(_filtroBusqueda) ?? false)
                        ).toList();
                  if (filtradas.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay categorías registradas o coincidentes.',
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
                                  Text(categoria.nombre, style: AppTypography.labelLarge),
                                  AppLayout.vXs,
                                  Text(
                                    categoria.descripcion?.isEmpty ?? true ? 'Sin descripción' : categoria.descripcion!,
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
                                  tooltip: 'Editar Categoría',
                                  onPressed: () => _mostrarModalRegistro(context, categoriaToEdit: categoria),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                  tooltip: 'Eliminar Categoría',
                                  onPressed: () => _confirmarEliminacion(context, categoria),
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
          Positioned(
            bottom: 16,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  mini: true,
                  heroTag: 'buscar_categoria',
                  onPressed: () => _mostrarBusqueda(context),
                  backgroundColor: const Color(0xFF64748B),
                  child: const Icon(Icons.search, color: Colors.white),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  heroTag: 'nueva_categoria',
                  onPressed: () => _mostrarModalRegistro(context),
                  backgroundColor: const Color(0xFF3B82F6),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminacion(BuildContext context, Categoria categoria) {
    AppDialog.show<void>(
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
    );
  }

  void _mostrarModalRegistro(BuildContext context, {Categoria? categoriaToEdit}) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: categoriaToEdit?.nombre ?? '');
    final descripcionController = TextEditingController(text: categoriaToEdit?.descripcion ?? '');
    final isEditing = categoriaToEdit != null;
    AppDialog.show<void>(
      context,
      title: isEditing ? 'Editar Categoría' : 'Nueva Categoría',
      content: SizedBox(
        width: 380,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(label: 'Nombre de la Categoría', controller: nombreController),
              AppLayout.vM,
              AppTextField(label: 'Descripción', controller: descripcionController),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
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
                isEditing
                    ? ref.read(categoriaControllerProvider.notifier).actualizar(cat)
                    : ref.read(categoriaControllerProvider.notifier).guardar(cat);
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
              }
            }
          },
        ),
      ],
    );
  }
}
