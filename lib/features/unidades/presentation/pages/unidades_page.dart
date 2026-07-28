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
import 'package:fiscogest_rd/features/inventario/presentation/providers/unidad_medida_providers.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/unidad_medida.dart';

class UnidadesPage extends ConsumerStatefulWidget {
  const UnidadesPage({super.key});

  @override
  ConsumerState<UnidadesPage> createState() => _UnidadesPageState();
}

class _UnidadesPageState extends ConsumerState<UnidadesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroBusqueda = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unidadesAsync = ref.watch(unidadMedidaControllerProvider);

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
                      const Text(
                        'Unidades de Medida',
                        style: AppTypography.h2,
                      ),
                      AppLayout.vXs,
                      Text(
                        'Gestión de unidades de venta y compra para el inventario.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  AppButton(
                    text: 'Nueva Unidad',
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
                  hint: 'Buscar unidad por nombre o abreviatura...',
                  prefixIcon: Icons.search,
                  onChanged: (value) => setState(() => _filtroBusqueda = value.toLowerCase()),
                ),
              ),
              AppLayout.vM,
              Expanded(
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: unidadesAsync.when(
                    data: (unidades) {
                      final filtradas = unidades.where((u) =>
                        u.nombre.toLowerCase().contains(_filtroBusqueda) ||
                        (u.abreviatura?.toLowerCase().contains(_filtroBusqueda) ?? false) ||
                        (u.descripcion?.toLowerCase().contains(_filtroBusqueda) ?? false)
                      ).toList();

                      if (filtradas.isEmpty) {
                        return const Center(
                          child: Text(
                            'No hay unidades registradas o coincidentes.',
                            style: AppTypography.bodyMedium,
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: AppSpacing.allS,
                        itemCount: filtradas.length,
                        separatorBuilder: (context, index) => const Divider(color: AppColors.grey200, height: 1),
                        itemBuilder: (context, index) {
                          final unidad = filtradas[index];
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
                                  child: Center(
                                    child: Text(
                                      unidad.abreviatura ?? '---',
                                      style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary),
                                    ),
                                  ),
                                ),
                                AppLayout.hM,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        unidad.nombre,
                                        style: AppTypography.labelLarge,
                                      ),
                                      AppLayout.vXs,
                                      Text(
                                        unidad.abreviatura != null && unidad.abreviatura!.isNotEmpty
                                            ? 'Abreviatura: ${unidad.abreviatura}'
                                            : unidad.descripcion?.isNotEmpty ?? true
                                                ? 'Sin descripción'
                                                : unidad.descripcion!,
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
                                      tooltip: 'Editar Unidad',
                                      onPressed: () => _mostrarModalRegistro(context, unidadToEdit: unidad),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                      tooltip: 'Eliminar Unidad',
                                      onPressed: () {
                                        AppDialog.show<void>(
                                          context,
                                          title: 'Confirmar Eliminación',
                                          message: '¿Está seguro de eliminar la unidad "${unidad.nombre}"?',
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancelar'),
                                            ),
                                            AppButton(
                                              text: 'Eliminar',
                                              onPressed: () {
                                                if (unidad.id != null) {
                                                  ref.read(unidadMedidaControllerProvider.notifier).eliminar(unidad.id!);
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

  void _mostrarModalRegistro(BuildContext context, {UnidadMedida? unidadToEdit}) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: unidadToEdit?.nombre ?? '');
    final abreviaturaController = TextEditingController(text: unidadToEdit?.abreviatura ?? '');
    final descripcionController = TextEditingController(text: unidadToEdit?.descripcion ?? '');
    final isEditing = unidadToEdit != null;

    AppDialog.show<void>(
      context,
      title: isEditing ? 'Editar Unidad' : 'Nueva Unidad',
      content: SizedBox(
        width: 380,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Nombre de la Unidad',
                controller: nombreController,
              ),
              AppLayout.vM,
              AppTextField(
                label: 'Abreviatura (ej. UND, KG)',
                controller: abreviaturaController,
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
                final und = UnidadMedida(
                  id: unidadToEdit?.id,
                  nombre: nombreController.text.trim(),
                  abreviatura: abreviaturaController.text.trim().isEmpty ? null : abreviaturaController.text.trim().toUpperCase(),
                  descripcion: descripcionController.text.trim().isEmpty ? null : descripcionController.text.trim(),
                  creadoEn: unidadToEdit?.creadoEn ?? DateTime.now(),
                  actualizadoEn: isEditing ? DateTime.now() : null,
                );

                if (isEditing) {
                  ref.read(unidadMedidaControllerProvider.notifier).actualizar(und);
                } else {
                  ref.read(unidadMedidaControllerProvider.notifier).guardar(und);
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
