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
import 'package:fiscogest_rd/features/proveedores/presentation/providers/proveedor_providers.dart';
import 'package:fiscogest_rd/features/proveedores/domain/entities/proveedor.dart';

class ProveedoresPage extends ConsumerStatefulWidget {
  const ProveedoresPage({super.key});
  static const String routeName = 'proveedores';
  @override
  ConsumerState<ProveedoresPage> createState() => _ProveedoresPageState();
}

class _ProveedoresPageState extends ConsumerState<ProveedoresPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroBusqueda = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proveedoresAsync = ref.watch(proveedorControllerProvider);
    final esPantallaPequena = MediaQuery.of(context).size.width < 800;

    return AppScaffold(
      title: 'Directorio de Proveedores',
      padding: AppSpacing.hL.copyWith(top: AppSpacing.m, bottom: AppSpacing.l),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              esPantallaPequena
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Administración de datos generales, contactos, RNC y direcciones comerciales.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppLayout.vM,
                        AppButton(
                          text: 'Nuevo Proveedor',
                          icon: Icons.business,
                          onPressed: () => _mostrarModalRegistro(context),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Administración de datos generales, contactos, RNC y direcciones comerciales.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        AppButton(
                          text: 'Nuevo Proveedor',
                          icon: Icons.business,
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
                  hint:
                      'Buscar proveedor por nombre, RNC, contacto o correo...',
                  prefixIcon: Icons.search,
                  onChanged: (value) =>
                      setState(() => _filtroBusqueda = value.toLowerCase()),
                ),
              ),
              AppLayout.vM,
              Expanded(
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: proveedoresAsync.when(
                    data: (proveedores) {
                      final filtrados = proveedores
                          .where(
                            (p) =>
                                p.nombre.toLowerCase().contains(
                                  _filtroBusqueda,
                                ) ||
                                p.rnc.toLowerCase().contains(_filtroBusqueda) ||
                                p.contacto.toLowerCase().contains(
                                  _filtroBusqueda,
                                ) ||
                                p.correo.toLowerCase().contains(
                                  _filtroBusqueda,
                                ),
                          )
                          .toList();
                      if (filtrados.isEmpty) {
                        return const Center(
                          child: Text(
                            'No hay proveedores registrados o coincidentes.',
                            style: AppTypography.bodyMedium,
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: AppSpacing.allS,
                        itemCount: filtrados.length,
                        separatorBuilder: (context, index) =>
                            const Divider(color: AppColors.grey200, height: 1),
                        itemBuilder: (context, index) {
                          final proveedor = filtrados[index];
                          return Padding(
                            padding: AppSpacing.vS,
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.grey50,
                                    borderRadius: AppRadius.allM,
                                  ),
                                  child: const Icon(
                                    Icons.store_mall_directory_outlined,
                                    color: AppColors.textPrimary,
                                    size: 22,
                                  ),
                                ),
                                AppLayout.hM,
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        proveedor.nombre,
                                        style: AppTypography.labelLarge,
                                      ),
                                      AppLayout.vXs,
                                      Text(
                                        'RNC: ${proveedor.rnc} | Contacto: ${proveedor.contacto}',
                                        style: AppTypography.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tel: ${proveedor.telefono} | ${proveedor.correo}',
                                        style: AppTypography.bodyMedium,
                                      ),
                                      AppLayout.vXs,
                                      Text(
                                        proveedor.direccion,
                                        style: AppTypography.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                                      tooltip: 'Editar Proveedor',
                                      onPressed: () => _mostrarModalRegistro(
                                        context,
                                        proveedorToEdit: proveedor,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.error,
                                        size: 20,
                                      ),
                                      tooltip: 'Eliminar Proveedor',
                                      onPressed: () {
                                        AppDialog.show<void>(
                                          context,
                                          title: 'Confirmar Eliminación',
                                          message:
                                              '¿Está seguro de eliminar al proveedor "${proveedor.nombre}"?',
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Cancelar'),
                                            ),
                                            AppButton(
                                              text: 'Eliminar',
                                              onPressed: () {
                                                if (proveedor.id != null) {
                                                  ref
                                                      .read(
                                                        proveedorControllerProvider
                                                            .notifier,
                                                      )
                                                      .eliminar(proveedor.id!);
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
    Proveedor? proveedorToEdit,
  }) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(
      text: proveedorToEdit?.nombre ?? '',
    );
    final contactoController = TextEditingController(
      text: proveedorToEdit?.contacto ?? '',
    );
    final direccionController = TextEditingController(
      text: proveedorToEdit?.direccion ?? '',
    );
    final telefonoController = TextEditingController(
      text: proveedorToEdit?.telefono ?? '',
    );
    final correoController = TextEditingController(
      text: proveedorToEdit?.correo ?? '',
    );
    final rncController = TextEditingController(
      text: proveedorToEdit?.rnc ?? '',
    );
    final isEditing = proveedorToEdit != null;

    AppDialog.show<void>(
      context,
      title: isEditing ? 'Editar Proveedor' : 'Nuevo Proveedor',
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Razón Social / Nombre Comercial',
                  controller: nombreController,
                ),
                AppLayout.vM,
                AppTextField(
                  label: 'RNC del Proveedor',
                  controller: rncController,
                ),
                AppLayout.vM,
                AppTextField(
                  label: 'Persona de Contacto',
                  controller: contactoController,
                ),
                AppLayout.vM,
                AppTextField(label: 'Teléfono', controller: telefonoController),
                AppLayout.vM,
                AppTextField(
                  label: 'Correo Electrónico',
                  controller: correoController,
                ),
                AppLayout.vM,
                AppTextField(
                  label: 'Dirección',
                  controller: direccionController,
                ),
              ],
            ),
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
                final prov = Proveedor(
                  id: proveedorToEdit?.id,
                  nombre: nombreController.text.trim(),
                  contacto: contactoController.text.trim(),
                  direccion: direccionController.text.trim(),
                  telefono: telefonoController.text.trim(),
                  correo: correoController.text.trim(),
                  rnc: rncController.text.trim(),
                );
                if (isEditing) {
                  ref
                      .read(proveedorControllerProvider.notifier)
                      .actualizar(prov);
                } else {
                  ref.read(proveedorControllerProvider.notifier).guardar(prov);
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
