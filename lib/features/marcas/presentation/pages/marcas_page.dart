import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_dialog.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
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
        content: AppTextField(
          controller: control,
          hint: 'Nombre de la marca...',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          AppButton(
            text: 'Buscar',
            onPressed: () => Navigator.pop(ctx, control.text),
          ),
        ],
      ),
    );
    if (resultado != null) {
      setState(() => _filtroBusqueda = resultado.toLowerCase());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final marcasAsync = ref.watch(marcaControllerProvider);

    return AppScaffold(
      title: 'Marcas',
      subtitle: 'Administración de marcas comerciales',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: const [],
      body: SafeArea(
        bottom: true,
        child: Stack(
          children: [
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  isMobile ? 16 : 20,
                  isMobile ? 16 : 24,
                  100,
                ),
                child: marcasAsync.when(
                  data: (marcas) {
                    final filtradas = _filtroBusqueda.isEmpty
                        ? marcas
                        : marcas
                            .where(
                              (m) =>
                                  m.nombre.toLowerCase().contains(_filtroBusqueda) ||
                                  (m.descripcion?.toLowerCase().contains(_filtroBusqueda) ?? false),
                            )
                            .toList();

                    if (filtradas.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay marcas registradas o coincidentes.',
                          style: AppTypography.bodyMedium,
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: filtradas.length,
                      separatorBuilder: (context, index) =>
                          const Divider(color: AppColors.grey200, height: 1),
                      itemBuilder: (context, index) {
                        final marca = filtradas[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: isMobile
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: AppColors.grey50,
                                            borderRadius: AppRadius.allM,
                                          ),
                                          child: const Icon(
                                            Icons.verified_outlined,
                                            color: AppColors.textPrimary,
                                            size: 20,
                                          ),
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
                                                marca.descripcion?.isEmpty ?? true
                                                    ? 'Sin descripción'
                                                    : marca.descripcion!,
                                                style: AppTypography.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                          tooltip: 'Editar Marca',
                                          onPressed: () => _mostrarModalRegistro(
                                            context,
                                            marcaToEdit: marca,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppColors.error,
                                            size: 20,
                                          ),
                                          tooltip: 'Eliminar Marca',
                                          onPressed: () =>
                                              _confirmarEliminacion(context, marca),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: AppColors.grey50,
                                        borderRadius: AppRadius.allM,
                                      ),
                                      child: const Icon(
                                        Icons.verified_outlined,
                                        color: AppColors.textPrimary,
                                        size: 20,
                                      ),
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
                                            marca.descripcion?.isEmpty ?? true
                                                ? 'Sin descripción'
                                                : marca.descripcion!,
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
                                          tooltip: 'Editar Marca',
                                          onPressed: () => _mostrarModalRegistro(
                                            context,
                                            marcaToEdit: marca,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppColors.error,
                                            size: 20,
                                          ),
                                          tooltip: 'Eliminar Marca',
                                          onPressed: () =>
                                              _confirmarEliminacion(context, marca),
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
                  error: (e, st) => Center(
                    child: Text('Error: $e', style: AppTypography.bodyMedium),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: isMobile ? 16 : 24,
              right: isMobile ? 16 : 24,
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
      ),
    );
  }

  void _confirmarEliminacion(BuildContext context, Marca marca) {
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
  }

  void _mostrarModalRegistro(BuildContext context, {Marca? marcaToEdit}) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(
      text: marcaToEdit?.nombre ?? '',
    );
    final descripcionController = TextEditingController(
      text: marcaToEdit?.descripcion ?? '',
    );
    final isEditing = marcaToEdit != null;

    AppDialog.show<void>(
      context,
      title: isEditing ? 'Editar Marca' : 'Nueva Marca',
      content: StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final anchoPantalla = MediaQuery.of(dialogContext).size.width;
          final anchoDialogo = anchoPantalla > 420 ? 400.0 : anchoPantalla * 0.85;

          bool validarNombre() {
            final limpio = nombreController.text.trim();
            return limpio.isNotEmpty && limpio.length <= 60;
          }

          return SizedBox(
            width: anchoDialogo,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FormField<String>(
                    initialValue: nombreController.text,
                    validator: (value) {
                      final limpio = value?.trim() ?? '';
                      if (limpio.isEmpty) return 'Ingrese el nombre de la marca';
                      if (limpio.length > 60) return 'Máximo 60 caracteres';
                      return null;
                    },
                    builder: (formFieldState) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          label: 'Nombre de la Marca *',
                          hint: 'Ej: Samsung, Toyota...',
                          controller: nombreController,
                          onChanged: (_) {
                            formFieldState.didChange(nombreController.text);
                            setDialogState(() {});
                          },
                        ),
                        if (formFieldState.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 12),
                            child: Text(
                              formFieldState.errorText!,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppLayout.vM,
                  FormField<String>(
                    initialValue: descripcionController.text,
                    validator: (value) {
                      final limpio = value?.trim() ?? '';
                      if (limpio.length > 200) return 'Máximo 200 caracteres';
                      return null;
                    },
                    builder: (formFieldState) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 80,
                          child: AppTextField(
                            label: 'Descripción',
                            hint: 'Breve descripción...',
                            controller: descripcionController,
                            onChanged: (_) {
                              formFieldState.didChange(descripcionController.text);
                              setDialogState(() {});
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2, right: 12),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${descripcionController.text.trim().length}/200',
                              style: AppTypography.bodySmall.copyWith(
                                color: descripcionController.text.trim().length > 200
                                    ? AppColors.error
                                    : AppColors.grey500,
                              ),
                            ),
                          ),
                        ),
                        if (formFieldState.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 12),
                            child: Text(
                              formFieldState.errorText!,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      AbsorbPointer(
                        absorbing: !validarNombre(),
                        child: Opacity(
                          opacity: validarNombre() ? 1.0 : 0.5,
                          child: AppButton(
                            text: isEditing ? 'Actualizar' : 'Guardar',
                            onPressed: () {
                              if (!validarNombre() || !formKey.currentState!.validate()) return;
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
                                if (!mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEditing
                                          ? 'Marca actualizada correctamente'
                                          : 'Marca registrada correctamente',
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString().replaceAll('Exception: ', '')),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
