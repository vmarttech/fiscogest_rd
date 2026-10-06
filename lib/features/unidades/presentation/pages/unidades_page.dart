import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_dialog.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/navigation/safe_back.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/unidad_medida_providers.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/unidad_medida.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

class UnidadesPage extends ConsumerStatefulWidget {
  const UnidadesPage({super.key});
  static const String routeName = 'unidades';

  @override
  ConsumerState<UnidadesPage> createState() => _UnidadesPageState();
}

class _UnidadesPageState extends ConsumerState<UnidadesPage> {
  String _filtroBusqueda = '';


  @override
  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final asyncList = ref.watch(unidadMedidaControllerProvider);

    return AppScaffold(
      title: 'Unidades de Medida',
      subtitle: 'Definición de unidades y abreviaturas',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Atrás',
        onPressed: () => safeBack(context, fallback: '/inventario'),
        style: IconButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        AppButton(
          text: isMobile ? 'Nuevo' : 'Nueva unidad',
          icon: Icons.straighten_rounded,
          onPressed: () => _mostrarModalRegistro(context),
        ),
      ],
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isMobile ? 560 : 920),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 12 : 20,
                isMobile ? 16 : 24,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AppTextField(
                      hint: 'Buscar...',
                      prefixIcon: Icons.search,
                      onChanged: (v) =>
                          setState(() => _filtroBusqueda = v.toLowerCase()),
                    ),
                  ),
                  SizedBox(height: isMobile ? 14 : 18),
                  Expanded(
                    child: asyncList.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                      error: (e, _) => Center(
                        child: Text(
                          'Error: $e',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      data: (items) {
                        final filtradas = _filtroBusqueda.isEmpty
                            ? items
                            : items.where((u) => u.nombre.toLowerCase().contains(_filtroBusqueda) || (u.abreviatura?.toLowerCase().contains(_filtroBusqueda) ?? false) || (u.descripcion?.toLowerCase().contains(_filtroBusqueda) ?? false)).toList();

                        if (filtradas.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.straighten,
                                      size: 32,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _filtroBusqueda.isEmpty
                                        ? 'Sin unidades aún'
                                        : 'Sin resultados',
                                    style: AppTypography.h4.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _filtroBusqueda.isEmpty
                                        ? 'Define la primera unidad de medida\npara usarla en productos y compras.'
                                        : 'Prueba con otro término de búsqueda.',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (isMobile) {
                          return ListView.separated(
                            itemCount: filtradas.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final u = filtradas[i];
                              return _UnidadCard(
                                item: u,
                                badge: (u.abreviatura != null && u.abreviatura!.isNotEmpty) ? u.abreviatura! : '—',
                                title: u.nombre,
                                subtitle: (u.abreviatura != null && u.abreviatura!.isNotEmpty) ? 'Abreviatura: ${u.abreviatura}' : ((u.descripcion?.isNotEmpty ?? false) ? u.descripcion! : 'Sin descripción'),
                                onEdit: () => _mostrarModalRegistro(
                                  context,
                                  unidadToEdit: u,
                                ),
                                onDelete: () => _onDelete(context, u),
                              );
                            },
                          );
                        }

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.10),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.04),
                                  border: const Border(
                                    bottom: BorderSide(color: AppColors.border),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 52),
                                    Expanded(
                                      child: Text(
                                        'NOMBRE',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 100,
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
                                  separatorBuilder: (_, __) => const Divider(
                                    height: 1,
                                    color: AppColors.border,
                                  ),
                                  itemBuilder: (_, i) {
                                    final u = filtradas[i];
                                    return Material(
                                      color: i.isEven
                                          ? Colors.white
                                          : AppColors.grey50.withValues(alpha: 0.55),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  (u.abreviatura != null && u.abreviatura!.isNotEmpty) ? u.abreviatura! : '—',
                                                  style: AppTypography.labelSmall
                                                      .copyWith(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    u.nombre,
                                                    style: AppTypography.bodyLarge
                                                        .copyWith(
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    (u.abreviatura != null && u.abreviatura!.isNotEmpty) ? 'Abreviatura: ${u.abreviatura}' : ((u.descripcion?.isNotEmpty ?? false) ? u.descripcion! : 'Sin descripción'),
                                                    style: AppTypography.bodySmall
                                                        .copyWith(
                                                      color:
                                                          AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  _mostrarModalRegistro(
                                                context,
                                                unidadToEdit: u,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: AppColors.error,
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  _onDelete(context, u),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onDelete(BuildContext context, UnidadMedida item) {
    _confirmarEliminacion(context, item);
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
              ref
                  .read(unidadMedidaControllerProvider.notifier)
                  .eliminar(unidad.id!);
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
          final anchoDialogo = anchoPantalla > 420
              ? 400.0
              : anchoPantalla * 0.85;

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
                      if (limpio.isEmpty) {
                        return 'Ingrese el nombre de la unidad';
                      }
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
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
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
                            formFieldState.didChange(
                              abreviaturaController.text,
                            );
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
                                color:
                                    abreviaturaController.text.trim().length > 8
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
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
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
                              formFieldState.didChange(
                                descripcionController.text,
                              );
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
                                color:
                                    descripcionController.text.trim().length >
                                        200
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
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
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
                              if (!validarNombre() ||
                                  !formKey.currentState!.validate()) {
                                return;
                              }
                              try {
                                final und = UnidadMedida(
                                  id: unidadToEdit?.id,
                                  nombre: nombreController.text.trim(),
                                  abreviatura:
                                      abreviaturaController.text.trim().isEmpty
                                      ? null
                                      : abreviaturaController.text
                                            .trim()
                                            .toUpperCase(),
                                  descripcion:
                                      descripcionController.text.trim().isEmpty
                                      ? null
                                      : descripcionController.text.trim(),
                                  creadoEn:
                                      unidadToEdit?.creadoEn ?? DateTime.now(),
                                  actualizadoEn: isEditing
                                      ? DateTime.now()
                                      : null,
                                );
                                if (isEditing) {
                                  ref
                                      .read(
                                        unidadMedidaControllerProvider.notifier,
                                      )
                                      .actualizar(und);
                                } else {
                                  ref
                                      .read(
                                        unidadMedidaControllerProvider.notifier,
                                      )
                                      .guardar(und);
                                }
                                if (!mounted) return;
                                Navigator.pop(context);
                                FiscoGestNotifications.show(
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
                                FiscoGestNotifications.show(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceAll(
                                        'Exception: ',
                                        '',
                                      ),
                                    ),
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


class _UnidadCard extends StatelessWidget {
  const _UnidadCard({
    required this.item,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
  });

  final dynamic item;
  final String badge;
  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                badge,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
