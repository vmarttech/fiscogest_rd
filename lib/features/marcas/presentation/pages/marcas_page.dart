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
import 'package:fiscogest_rd/features/inventario/presentation/providers/marca_providers.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/marca.dart';

class MarcasPage extends ConsumerStatefulWidget {
  const MarcasPage({super.key});
  static const String routeName = 'marcas';
  @override
  ConsumerState<MarcasPage> createState() => _MarcasPageState();
}

class _MarcasPageState extends ConsumerState<MarcasPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroBusqueda = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marcasAsync = ref.watch(marcaControllerProvider);
    return AppScaffold(
      title: 'Marcas',
      padding: AppSpacing.hL.copyWith(top: AppSpacing.m, bottom: AppSpacing.l),
      body: Stack(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Administración de marcas comerciales del sistema.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  AppLayout.vM,
                  AppCard(
                    padding: AppSpacing.hM.copyWith(top: AppSpacing.s, bottom: AppSpacing.s),
                    child: AppTextField(
                      controller: _searchController,
                      hint: 'Buscar marca por nombre...',
                      prefixIcon: Icons.search,
                      onChanged: (value) => setState(() => _filtroBusqueda = value.toLowerCase()),
                    ),
                  ),
                  AppLayout.vM,
                  Expanded(
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      child: marcasAsync.when(
                        data: (marcas) {
                          final filtradas = marcas.where((m) =>
                            m.nombre.toLowerCase().contains(_filtroBusqueda) ||
                            (m.descripcion?.toLowerCase().contains(_filtroBusqueda) ?? false)
                          ).toList();
                          if (filtradas.isEmpty) {
                            return const Center(
                              child: Text(
                                'No hay marcas registradas o coincidentes.',
                                style: AppTypography.bodyMedium,
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: AppSpacing.allS,
                            itemCount: filtradas.length,
                            separatorBuilder: (context, index) => const Divider(color: AppColors.grey200, height: 1),
                            itemBuilder: (context, index) {
                              final marca = filtradas[index];
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
                                      child: const Icon(Icons.verified_outlined, color: AppColors.textPrimary, size: 20),
                                    ),
                                    AppLayout.hM,
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            marca.nombre,
                                            style: AppTypography.labelLarge,
                                          ),
                                          AppLayout.vXs,
                                          Text(
                                            marca.descripcion?.isEmpty ?? true ? 'Sin descripción' : marca.descripcion!,
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
                                          tooltip: 'Editar Marca',
                                          onPressed: () => _mostrarModalRegistro(context, marcaToEdit: marca),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                          tooltip: 'Eliminar Marca',
                                          onPressed: () {
                                            AppDialog.show<void>(
                                              context,
                                              title: 'Confirmar Eliminación',
                                              message: '¿Está seguro de eliminar la marca "${marca.nombre}"?',
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Cancelar'),
                                                ),
                                                AppButton(
                                                  text: 'Eliminar',
                                                  onPressed: () {
                                                    if (marca.id != null) {
                                                      ref.read(marcaControllerProvider.notifier).eliminar(marca.id!);
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
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => _mostrarModalRegistro(context),
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarModalRegistro(BuildContext context, {Marca? marcaToEdit}) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: marcaToEdit?.nombre ?? '');
    final descripcionController = TextEditingController(text: marcaToEdit?.descripcion ?? '');
    final isEditing = marcaToEdit != null;
    AppDialog.show<void>(
      context,
      title: isEditing ? 'Editar Marca' : 'Nueva Marca',
      content: SizedBox(
        width: 380,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Nombre de la Marca',
                controller: nombreController,
              ),
              AppLayout.vM,
              AppTextField(
                label: 'Descripción',
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
                final mar = Marca(
                  id: marcaToEdit?.id,
                  nombre: nombreController.text.trim(),
                  descripcion: descripcionController.text.trim(),
                  creadoEn: marcaToEdit?.creadoEn ?? DateTime.now(),
                  actualizadoEn: isEditing ? DateTime.now() : null,
                );
                if (isEditing) {
                  ref.read(marcaControllerProvider.notifier).actualizar(mar);
                } else {
                  ref.read(marcaControllerProvider.notifier).guardar(mar);
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
