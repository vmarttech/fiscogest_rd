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
import 'package:fiscogest_rd/features/inventario/presentation/providers/marca_providers.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/marca.dart';

class MarcasPage extends ConsumerStatefulWidget {
  const MarcasPage({super.key});
  static const String routeName = 'marcas';
  @override
  ConsumerState<MarcasPage> createState() => _MarcasPageState();
}

class _MarcasPageState extends ConsumerState<MarcasPage> {
  String _filtroBusqueda = '';

  void _mostrarBusqueda(BuildContext context) async {
    final control = TextEditingController(text: _filtroBusqueda);
    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buscar Marca'),
        content: AppTextField(controller: control, hint: 'Nombre de la marca...'),
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
    final marcasAsync = ref.watch(marcaControllerProvider);
    return AppScaffold(
      
      padding: AppSpacing.hL.copyWith(top: AppSpacing.m, bottom: AppSpacing.l),
      body: Stack(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: marcasAsync.when(
                data: (marcas) {
                  final filtradas = _filtroBusqueda.isEmpty
                      ? marcas
                      : marcas.where((m) =>
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
                                  Text(marca.nombre, style: AppTypography.labelLarge),
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
                                  onPressed: () => _confirmarEliminacion(context, marca),
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
                  heroTag: 'buscar_marca',
                  onPressed: () => _mostrarBusqueda(context),
                  backgroundColor: const Color(0xFF64748B),
                  child: const Icon(Icons.search, color: Colors.white),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  heroTag: 'nueva_marca',
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

  void _confirmarEliminacion(BuildContext context, Marca marca) {
    AppDialog.show<void>(
      context,
      title: 'Confirmar Eliminación',
      message: '¿Está seguro de eliminar la marca "${marca.nombre}"?',
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        AppButton(
          text: 'Eliminar',
          onPressed: () {
            if (marca.id != null) ref.read(marcaControllerProvider.notifier).eliminar(marca.id!);
            Navigator.pop(context);
          },
        ),
      ],
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
              AppTextField(label: 'Nombre de la Marca', controller: nombreController),
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
                final mar = Marca(
                  id: marcaToEdit?.id,
                  nombre: nombreController.text.trim(),
                  descripcion: descripcionController.text.trim(),
                  creadoEn: marcaToEdit?.creadoEn ?? DateTime.now(),
                  actualizadoEn: isEditing ? DateTime.now() : null,
                );
                isEditing
                    ? ref.read(marcaControllerProvider.notifier).actualizar(mar)
                    : ref.read(marcaControllerProvider.notifier).guardar(mar);
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
