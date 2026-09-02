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
import 'package:fiscogest_rd/features/presentaciones/presentation/providers/presentacion_providers.dart';
import 'package:fiscogest_rd/features/presentaciones/domain/entities/presentacion.dart';

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
  Widget build(BuildContext context) {
    final presentacionesAsync = ref.watch(presentacionControllerProvider);
    final esPantallaPequena = MediaQuery.of(context).size.width < 600;

    return AppScaffold(
      title: 'Presentaciones',
      padding: AppSpacing.hL.copyWith(top: AppSpacing.m, bottom: AppSpacing.l),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              esPantallaPequena
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Administración de unidades y presentaciones de productos.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppLayout.vM,
                        AppButton(
                          text: 'Nueva Presentación',
                          icon: Icons.add,
                          onPressed: () => _mostrarModalRegistro(context),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Administración de unidades y presentaciones de productos.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        AppButton(
                          text: 'Nueva Presentación',
                          icon: Icons.add,
                          onPressed: () => _mostrarModalRegistro(context),
                        ),
                      ],
                    ),
              AppLayout.vM,
              AppCard(
                padding: AppSpacing.hM.copyWith(
                  top: AppSpacing.s,
                  bottom: AppSpacing.s,
                ),
                child: AppTextField(
                  controller: _searchController,
                  hint: 'Buscar presentación por nombre o abreviatura...',
                  prefixIcon: Icons.search,
                  onChanged: (value) =>
                      setState(() => _filtroBusqueda = value.toLowerCase()),
                ),
              ),
              AppLayout.vM,
              Expanded(
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: presentacionesAsync.when(
                    data: (presentaciones) {
                      final filtradas = presentaciones
                          .where(
                            (p) =>
                                p.nombre.toLowerCase().contains(
                                  _filtroBusqueda,
                                ) ||
                                p.abreviatura.toLowerCase().contains(
                                  _filtroBusqueda,
                                ),
                          )
                          .toList();
                      if (filtradas.isEmpty) {
                        return const Center(
                          child: Text(
                            'No hay presentaciones registradas o coincidentes.',
                            style: AppTypography.bodyMedium,
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: AppSpacing.allS,
                        itemCount: filtradas.length,
                        separatorBuilder: (context, index) =>
                            const Divider(color: AppColors.grey200, height: 1),
                        itemBuilder: (context, index) {
                          final presentacion = filtradas[index];
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
                                      presentacion.abreviatura,
                                      style: AppTypography.labelMedium.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                AppLayout.hM,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        presentacion.nombre,
                                        style: AppTypography.labelLarge,
                                      ),
                                      AppLayout.vXs,
                                      Text(
                                        'Abreviatura: ${presentacion.abreviatura}',
                                        style: AppTypography.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      tooltip: 'Editar Presentación',
                                      onPressed: () => _mostrarModalRegistro(
                                        context,
                                        presentacionToEdit: presentacion,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.error,
                                        size: 20,
                                      ),
                                      tooltip: 'Eliminar Presentación',
                                      onPressed: () {
                                        AppDialog.show<void>(
                                          context,
                                          title: 'Confirmar Eliminación',
                                          message:
                                              '¿Está seguro de eliminar la presentación "${presentacion.nombre}"?',
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Cancelar'),
                                            ),
                                            AppButton(
                                              text: 'Eliminar',
                                              onPressed: () {
                                                if (presentacion.id != null) {
                                                  ref
                                                      .read(
                                                        presentacionControllerProvider
                                                            .notifier,
                                                      )
                                                      .eliminar(
                                                        presentacion.id!,
                                                      );
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
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(
                      child: Text('Error: $e', style: AppTypography.bodyMedium),
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
                ScaffoldMessenger.of(context).showSnackBar(
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
