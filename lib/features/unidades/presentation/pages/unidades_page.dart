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
import 'package:fiscogest_rd/features/inventario/presentation/providers/unidad_medida_providers.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/unidad_medida.dart';

class UnidadesPage extends ConsumerStatefulWidget {
  const UnidadesPage({super.key});
  static const String routeName = 'unidades';

  @override
  ConsumerState<UnidadesPage> createState() => _UnidadesPageState();
}

class _UnidadesPageState extends ConsumerState<UnidadesPage> {
  String _filtroBusqueda = '';

  void _mostrarBusqueda(BuildContext context) async {
    final control = TextEditingController(text: _filtroBusqueda);
    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buscar Unidad'),
        content: AppTextField(
          controller: control,
          hint: 'Nombre o abreviatura...',
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
    final unidadesAsync = ref.watch(unidadMedidaControllerProvider);

    return AppScaffold(
      title: 'Unidades de Medida',
      subtitle: 'Definición de unidades y abreviaturas',
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
                constraints: const BoxConstraints(maxWidth: 1320),
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 8,
                  isMobile ? 12 : 16,
                  isMobile ? 16 : 8,
                  100,
                ),
                child: unidadesAsync.when(
                  data: (unidades) {
                    final filtradas = _filtroBusqueda.isEmpty
                        ? unidades
                        : unidades
                            .where(
                              (u) =>
                                  u.nombre.toLowerCase().contains(_filtroBusqueda) ||
                                  (u.abreviatura?.toLowerCase().contains(_filtroBusqueda) ?? false) ||
                                  (u.descripcion?.toLowerCase().contains(_filtroBusqueda) ?? false),
                            )
                            .toList();

                    if (filtradas.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay unidades registradas o coincidentes.',
                          style: AppTypography.bodyMedium,
                        ),
                      );
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.grey900.withValues(alpha: 0.05),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          if (!isMobile)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8FAFC),
                                border: Border(
                                  bottom: BorderSide(color: AppColors.border),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 54),
                                  Expanded(
                                    child: Text(
                                      'UNIDAD',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 96,
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
                      separatorBuilder: (context, index) =>
                          const Divider(color: AppColors.border, height: 1),
                      itemBuilder: (context, index) {
                        final unidad = filtradas[index];
                        final subtitulo = unidad.abreviatura != null && unidad.abreviatura!.isNotEmpty
                            ? 'Abreviatura: ${unidad.abreviatura}'
                            : unidad.descripcion?.isNotEmpty ?? true
                                ? 'Sin descripción'
                                : unidad.descripcion!;

                        return Material(
                          color: index.isEven
                              ? AppColors.white
                              : AppColors.grey50.withValues(alpha: 0.55),
                          child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
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
                                          child: Center(
                                            child: Text(
                                              unidad.abreviatura ?? '---',
                                              style: AppTypography.labelMedium.copyWith(
                                                color: AppColors.textPrimary,
                                              ),
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
                                                subtitulo,
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
                                          tooltip: 'Editar Unidad',
                                          onPressed: () => _mostrarModalRegistro(
                                            context,
                                            unidadToEdit: unidad,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppColors.error,
                                            size: 20,
                                          ),
                                          tooltip: 'Eliminar Unidad',
                                          onPressed: () =>
                                              _confirmarEliminacion(context, unidad),
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
                                      child: Center(
                                        child: Text(
                                          unidad.abreviatura ?? '---',
                                          style: AppTypography.labelMedium.copyWith(
                                            color: AppColors.textPrimary,
                                          ),
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
                                            subtitulo,
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
                                          tooltip: 'Editar Unidad',
                                          onPressed: () => _mostrarModalRegistro(
                                            context,
                                            unidadToEdit: unidad,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppColors.error,
                                            size: 20,
                                          ),
                                          tooltip: 'Eliminar Unidad',
                                          onPressed: () =>
                                              _confirmarEliminacion(context, unidad),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                        );
                      },
                      ), // ListView
                          ), // Expanded
                        ], // Column children
                      ), // Column
                    ); // Container
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
                    heroTag: 'buscar_unidad',
                    onPressed: () => _mostrarBusqueda(context),
                    backgroundColor: const Color(0xFF64748B),
                    child: const Icon(Icons.search, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    heroTag: 'nueva_unidad',
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

  void _confirmarEliminacion(BuildContext context, UnidadMedida unidad) {
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
  }

  void _mostrarModalRegistro(
    BuildContext context, {
    UnidadMedida? unidadToEdit,
  }) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(
      text: unidadToEdit?.nombre ?? '',
    );
    final abreviaturaController = TextEditingController(
      text: unidadToEdit?.abreviatura ?? '',
    );
    final descripcionController = TextEditingController(
      text: unidadToEdit?.descripcion ?? '',
    );
    final isEditing = unidadToEdit != null;

    AppDialog.show<void>(
      context,
      title: isEditing ? 'Editar Unidad' : 'Nueva Unidad',
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
                      if (limpio.isEmpty) return 'Ingrese el nombre de la unidad';
                      if (limpio.length > 60) return 'Máximo 60 caracteres';
                      return null;
                    },
                    builder: (formFieldState) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          label: 'Nombre de la Unidad *',
                          hint: 'Ej: Unidad, Kilogramo, Litro...',
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
                    initialValue: abreviaturaController.text,
                    validator: (value) {
                      final limpio = value?.trim() ?? '';
                      if (limpio.length > 8) return 'Máximo 8 caracteres';
                      return null;
                    },
                    builder: (formFieldState) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          label: 'Abreviatura',
                          hint: 'Ej: UND, KG, L...',
                          controller: abreviaturaController,
                          onChanged: (_) {
                            formFieldState.didChange(abreviaturaController.text);
                            setDialogState(() {});
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2, right: 12),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${abreviaturaController.text.trim().length}/8',
                              style: AppTypography.bodySmall.copyWith(
                                color: abreviaturaController.text.trim().length > 8
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
                                final und = UnidadMedida(
                                  id: unidadToEdit?.id,
                                  nombre: nombreController.text.trim(),
                                  abreviatura: abreviaturaController.text.trim().isEmpty
                                      ? null
                                      : abreviaturaController.text.trim().toUpperCase(),
                                  descripcion: descripcionController.text.trim().isEmpty
                                      ? null
                                      : descripcionController.text.trim(),
                                  creadoEn: unidadToEdit?.creadoEn ?? DateTime.now(),
                                  actualizadoEn: isEditing ? DateTime.now() : null,
                                );
                                if (isEditing) {
                                  ref.read(unidadMedidaControllerProvider.notifier).actualizar(und);
                                } else {
                                  ref.read(unidadMedidaControllerProvider.notifier).guardar(und);
                                }
                                if (!mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEditing
                                          ? 'Unidad actualizada correctamente'
                                          : 'Unidad registrada correctamente',
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
