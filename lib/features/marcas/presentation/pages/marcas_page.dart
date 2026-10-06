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
import 'package:fiscogest_rd/features/inventario/presentation/providers/marca_providers.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/marca.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

class MarcasPage extends ConsumerStatefulWidget {
  const MarcasPage({super.key});
  static const String routeName = 'marcas';

  @override
  ConsumerState<MarcasPage> createState() => _MarcasPageState();
}

class _MarcasPageState extends ConsumerState<MarcasPage> {
  String _filtroBusqueda = '';


  @override
  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final marcasAsync = ref.watch(marcaControllerProvider);

    return AppScaffold(
      title: 'Marcas',
      subtitle: 'Administración de marcas comerciales',
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
          text: isMobile ? 'Nuevo' : 'Nueva marca',
          icon: Icons.sell_outlined,
          onPressed: () => _mostrarModalRegistro(context),
        ),
      ],
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? 560 : 920,
            ),
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
                      hint: 'Buscar por nombre o descripción...',
                      prefixIcon: Icons.search,
                      onChanged: (v) =>
                          setState(() => _filtroBusqueda = v.toLowerCase()),
                    ),
                  ),
                  SizedBox(height: isMobile ? 14 : 18),
                  Expanded(
                    child: marcasAsync.when(
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
                      data: (marcas) {
                        final filtradas = _filtroBusqueda.isEmpty
                            ? marcas
                            : marcas
                                .where(
                                  (m) =>
                                      m.nombre.toLowerCase().contains(
                                        _filtroBusqueda,
                                      ) ||
                                      (m.descripcion?.toLowerCase().contains(
                                            _filtroBusqueda,
                                          ) ??
                                          false),
                                )
                                .toList();

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
                                      color: AppColors.primary.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.verified_outlined,
                                      size: 32,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _filtroBusqueda.isEmpty
                                        ? 'Sin marcas aún'
                                        : 'Sin resultados',
                                    style: AppTypography.h4.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _filtroBusqueda.isEmpty
                                        ? 'Registra la primera marca comercial\npara organizar tus productos.'
                                        : 'Prueba con otro nombre o descripción.',
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
                              final m = filtradas[i];
                              return _MarcaCard(
                                marca: m,
                                onEdit: () => _mostrarModalRegistro(
                                  context,
                                  marcaToEdit: m,
                                ),
                                onDelete: () =>
                                    _confirmarEliminacion(context, m),
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
                                  color: AppColors.primary.withValues(
                                    alpha: 0.04,
                                  ),
                                  border: const Border(
                                    bottom: BorderSide(color: AppColors.border),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 52),
                                    Expanded(
                                      child: Text(
                                        'MARCA',
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
                                    final m = filtradas[i];
                                    return Material(
                                      color: i.isEven
                                          ? Colors.white
                                          : AppColors.grey50.withValues(
                                              alpha: 0.55,
                                            ),
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
                                              child: const Icon(
                                                Icons.verified_outlined,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    m.nombre,
                                                    style: AppTypography
                                                        .bodyLarge
                                                        .copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    (m.descripcion?.isEmpty ??
                                                            true)
                                                        ? 'Sin descripción'
                                                        : m.descripcion!,
                                                    style: AppTypography
                                                        .bodySmall
                                                        .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
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
                                              tooltip: 'Editar',
                                              onPressed: () =>
                                                  _mostrarModalRegistro(
                                                context,
                                                marcaToEdit: m,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: AppColors.error,
                                                size: 20,
                                              ),
                                              tooltip: 'Eliminar',
                                              onPressed: () =>
                                                  _confirmarEliminacion(
                                                context,
                                                m,
                                              ),
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
                        return 'Ingrese el nombre de la marca';
                      }
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
                                final mar = Marca(
                                  id: marcaToEdit?.id,
                                  nombre: nombreController.text.trim(),
                                  descripcion: descripcionController.text
                                      .trim(),
                                  creadoEn:
                                      marcaToEdit?.creadoEn ?? DateTime.now(),
                                  actualizadoEn: isEditing
                                      ? DateTime.now()
                                      : null,
                                );
                                if (isEditing) {
                                  ref
                                      .read(marcaControllerProvider.notifier)
                                      .actualizar(mar);
                                } else {
                                  ref
                                      .read(marcaControllerProvider.notifier)
                                      .guardar(mar);
                                }
                                if (!mounted) return;
                                Navigator.pop(context);
                                FiscoGestNotifications.show(
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


class _MarcaCard extends StatelessWidget {
  const _MarcaCard({
    required this.marca,
    required this.onEdit,
    required this.onDelete,
  });

  final Marca marca;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final desc = (marca.descripcion?.isEmpty ?? true)
        ? 'Sin descripción'
        : marca.descripcion!;

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
            child: const Icon(
              Icons.verified_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  marca.nombre,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
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
