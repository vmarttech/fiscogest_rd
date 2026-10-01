import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_dialog.dart';
import 'package:fiscogest_rd/features/proveedores/presentation/providers/proveedor_providers.dart';
import 'package:fiscogest_rd/features/proveedores/domain/entities/proveedor.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

class ProveedoresPage extends ConsumerStatefulWidget {
  const ProveedoresPage({super.key});
  static String routeName = 'proveedores';

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
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final proveedoresAsync = ref.watch(proveedorControllerProvider);

    return AppScaffold(
      title: 'Proveedores',
      subtitle: 'Directorio de proveedores y contactos',
      actions: [
        if (!isMobile)
          AppButton(
            text: 'Nuevo proveedor',
            icon: Icons.business,
            onPressed: () => _mostrarModalRegistro(context),
          ),
      ],
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _mostrarModalRegistro(context),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isMobile ? 560 : 1100),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 12 : 20,
                isMobile ? 16 : 24,
                isMobile ? 88 : 24,
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
                      controller: _searchController,
                      hint: 'Buscar por nombre, RNC, contacto o correo...',
                      prefixIcon: Icons.search,
                      onChanged: (value) =>
                          setState(() => _filtroBusqueda = value.toLowerCase()),
                    ),
                  ),
                  SizedBox(height: isMobile ? 14 : 18),
                  Expanded(
                    child: proveedoresAsync.when(
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
                      data: (proveedores) {
                        final filtrados = proveedores.where((p) {
                          final nombre = p.nombreEmpresa.toLowerCase();
                          final rnc = (p.rnc ?? '').toLowerCase();
                          final contacto = (p.nombreContacto ?? '').toLowerCase();
                          final correo = (p.email ?? '').toLowerCase();
                          return nombre.contains(_filtroBusqueda) ||
                              rnc.contains(_filtroBusqueda) ||
                              contacto.contains(_filtroBusqueda) ||
                              correo.contains(_filtroBusqueda);
                        }).toList();

                        if (filtrados.isEmpty) {
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
                                      Icons.store_mall_directory_outlined,
                                      size: 32,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _filtroBusqueda.isEmpty
                                        ? 'Sin proveedores aún'
                                        : 'Sin resultados',
                                    style: AppTypography.h4.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _filtroBusqueda.isEmpty
                                        ? 'Registra el primer proveedor\npara compras y cuentas por pagar.'
                                        : 'Prueba con otro término de búsqueda.',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                  if (_filtroBusqueda.isEmpty) ...[
                                    const SizedBox(height: 18),
                                    AppButton(
                                      text: 'Nuevo proveedor',
                                      icon: Icons.business,
                                      onPressed: () =>
                                          _mostrarModalRegistro(context),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }

                        if (isMobile) {
                          return ListView.separated(
                            itemCount: filtrados.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final proveedor = filtrados[i];
                              return _ProveedorCardMobile(
                                proveedor: proveedor,
                                onEdit: () => _mostrarModalRegistro(
                                  context,
                                  proveedorToEdit: proveedor,
                                ),
                                onDelete: () =>
                                    _confirmarEliminarProveedor(context, proveedor),
                              );
                            },
                          );
                        }

                        // Desktop: filas en panel
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
                                      flex: 2,
                                      child: Text(
                                        'PROVEEDOR',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'CONTACTO',
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
                                  itemCount: filtrados.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    height: 1,
                                    color: AppColors.border,
                                  ),
                                  itemBuilder: (_, i) {
                                    final proveedor = filtrados[i];
                                    final direccionCompleta = [
                                      if (proveedor.direccion?.isNotEmpty ?? false)
                                        proveedor.direccion,
                                      if (proveedor.ciudad?.isNotEmpty ?? false)
                                        proveedor.ciudad,
                                      if (proveedor.provincia?.isNotEmpty ?? false)
                                        proveedor.provincia,
                                    ].join(', ');
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
                                              child: const Icon(
                                                Icons.store_mall_directory_outlined,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    proveedor.nombreEmpresa,
                                                    style: AppTypography.bodyLarge
                                                        .copyWith(
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'RNC: ${proveedor.rnc ?? '—'} · ${proveedor.nombreContacto ?? '—'}',
                                                    style: AppTypography.bodySmall
                                                        .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
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
                                                    '${proveedor.telefono ?? '—'} · ${proveedor.email ?? '—'}',
                                                    style: AppTypography.bodySmall,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    direccionCompleta.isNotEmpty
                                                        ? direccionCompleta
                                                        : 'Sin dirección',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: AppTypography.bodySmall
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
                                              onPressed: () =>
                                                  _mostrarModalRegistro(
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
                                              onPressed: () =>
                                                  _confirmarEliminarProveedor(
                                                context,
                                                proveedor,
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

  void _confirmarEliminarProveedor(BuildContext context, Proveedor proveedor) {
    AppDialog.show<void>(
      context,
      title: 'Confirmar Eliminación',
      message:
          '¿Está seguro de eliminar al proveedor "${proveedor.nombreEmpresa}"?',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        AppButton(
          text: 'Eliminar',
          onPressed: () {
            if (proveedor.id != null) {
              ref.read(proveedorControllerProvider.notifier).eliminar(proveedor.id!);
            }
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _mostrarModalRegistro(
    BuildContext context, {
    Proveedor? proveedorToEdit,
  }) {
    final formKey = GlobalKey<FormState>();
    final nombreEmpresaController = TextEditingController(
      text: proveedorToEdit?.nombreEmpresa ?? '',
    );
    final nombreContactoController = TextEditingController(
      text: proveedorToEdit?.nombreContacto ?? '',
    );
    final direccionController = TextEditingController(
      text: proveedorToEdit?.direccion ?? '',
    );
    final ciudadController = TextEditingController(
      text: proveedorToEdit?.ciudad ?? '',
    );
    final provinciaController = TextEditingController(
      text: proveedorToEdit?.provincia ?? '',
    );
    final telefonoController = TextEditingController(
      text: proveedorToEdit?.telefono ?? '',
    );
    final celularController = TextEditingController(
      text: proveedorToEdit?.celular ?? '',
    );
    final whatsAppController = TextEditingController(
      text: proveedorToEdit?.whatsApp ?? '',
    );
    final emailController = TextEditingController(
      text: proveedorToEdit?.email ?? '',
    );
    final rncController = TextEditingController(
      text: proveedorToEdit?.rnc ?? '',
    );
    final limiteCreditoController = TextEditingController(
      text: proveedorToEdit?.limiteCredito.toString(),
    );
    final diasCreditoController = TextEditingController(
      text: proveedorToEdit?.diasCredito.toString(),
    );
    final condicionesController = TextEditingController(
      text: proveedorToEdit?.condicionesNota ?? '',
    );
    final isEditing = proveedorToEdit != null;
    final mobile = MediaQuery.sizeOf(context).width < 600;

    void guardar() {
      if (!formKey.currentState!.validate()) return;
      try {
        final prov = Proveedor(
          id: proveedorToEdit?.id,
          nombreEmpresa: nombreEmpresaController.text.trim(),
          nombreContacto: nombreContactoController.text.trim().isNotEmpty
              ? nombreContactoController.text.trim()
              : null,
          rnc: rncController.text.trim().isNotEmpty
              ? rncController.text.trim()
              : null,
          direccion: direccionController.text.trim().isNotEmpty
              ? direccionController.text.trim()
              : null,
          ciudad: ciudadController.text.trim().isNotEmpty
              ? ciudadController.text.trim()
              : null,
          provincia: provinciaController.text.trim().isNotEmpty
              ? provinciaController.text.trim()
              : null,
          telefono: telefonoController.text.trim().isNotEmpty
              ? telefonoController.text.trim()
              : null,
          celular: celularController.text.trim().isNotEmpty
              ? celularController.text.trim()
              : null,
          whatsApp: whatsAppController.text.trim().isNotEmpty
              ? whatsAppController.text.trim()
              : null,
          email: emailController.text.trim().isNotEmpty
              ? emailController.text.trim()
              : null,
          limiteCredito:
              double.tryParse(limiteCreditoController.text.trim()) ?? 0.0,
          diasCredito: int.tryParse(diasCreditoController.text.trim()) ?? 0,
          condicionesNota: condicionesController.text.trim().isNotEmpty
              ? condicionesController.text.trim()
              : null,
          estado: 'Activo',
          fechaCreacion: proveedorToEdit?.fechaCreacion ?? DateTime.now(),
          fechaActualizacion: DateTime.now(),
        );
        if (isEditing) {
          ref.read(proveedorControllerProvider.notifier).actualizar(prov);
        } else {
          ref.read(proveedorControllerProvider.notifier).guardar(prov);
        }
        Navigator.pop(context);
      } catch (e) {
        FiscoGestNotifications.show(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
          ),
        );
      }
    }

    Widget formFields({required bool compact}) {
      final gap = compact ? const SizedBox(height: 12) : AppLayout.vM;
      return Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Razón Social / Nombre Comercial',
              controller: nombreEmpresaController,
            ),
            gap,
            AppTextField(
              label: 'RNC del Proveedor',
              controller: rncController,
            ),
            gap,
            AppTextField(
              label: 'Persona de Contacto',
              controller: nombreContactoController,
            ),
            gap,
            AppTextField(
              label: 'Dirección',
              controller: direccionController,
            ),
            gap,
            if (compact) ...[
              AppTextField(label: 'Ciudad', controller: ciudadController),
              gap,
              AppTextField(
                label: 'Provincia',
                controller: provinciaController,
              ),
              gap,
              AppTextField(label: 'Teléfono', controller: telefonoController),
              gap,
              AppTextField(label: 'Celular', controller: celularController),
              gap,
              AppTextField(label: 'WhatsApp', controller: whatsAppController),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Ciudad',
                      controller: ciudadController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Provincia',
                      controller: provinciaController,
                    ),
                  ),
                ],
              ),
              gap,
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Teléfono',
                      controller: telefonoController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Celular',
                      controller: celularController,
                    ),
                  ),
                ],
              ),
              gap,
              AppTextField(
                label: 'WhatsApp',
                controller: whatsAppController,
              ),
            ],
            gap,
            AppTextField(
              label: 'Correo Electrónico',
              controller: emailController,
            ),
            gap,
            if (compact) ...[
              AppTextField(
                label: 'Límite de Crédito',
                controller: limiteCreditoController,
              ),
              gap,
              AppTextField(
                label: 'Días de Crédito',
                controller: diasCreditoController,
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Límite de Crédito',
                      controller: limiteCreditoController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Días de Crédito',
                      controller: diasCreditoController,
                    ),
                  ),
                ],
              ),
            ],
            gap,
            AppTextField(
              label: 'Condiciones',
              controller: condicionesController,
            ),
          ],
        ),
      );
    }

    if (mobile) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: bottom),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
                  maxWidth: 560,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isEditing ? 'Editar Proveedor' : 'Nuevo Proveedor',
                              style: AppTypography.h4.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        child: formFields(compact: true),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              text: isEditing ? 'Actualizar' : 'Guardar',
                              onPressed: guardar,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      return;
    }

    // PC / tablet: diálogo centrado y compacto (no estirado de arriba a abajo)
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final maxFormH = MediaQuery.sizeOf(ctx).height * 0.48;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          isEditing ? 'Editar Proveedor' : 'Nuevo Proveedor',
                          style: AppTypography.h4.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxFormH),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: formFields(compact: false),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      AppButton(
                        text: isEditing ? 'Actualizar' : 'Guardar',
                        onPressed: guardar,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


class _ProveedorCardMobile extends StatelessWidget {
  const _ProveedorCardMobile({
    required this.proveedor,
    required this.onEdit,
    required this.onDelete,
  });

  final Proveedor proveedor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final sub = 'RNC: ${proveedor.rnc ?? '—'} · ${proveedor.nombreContacto ?? 'Sin contacto'}';
    final tel = proveedor.telefono ?? proveedor.celular ?? '—';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.store_mall_directory_outlined,
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
                      proveedor.nombreEmpresa,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Tel: $tel${proveedor.email != null ? ' · ${proveedor.email}' : ''}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
        ],
      ),
    );
  }
}
