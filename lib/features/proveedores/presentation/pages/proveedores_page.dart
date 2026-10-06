import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
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
        AppButton(
          text: isMobile ? 'Nuevo' : 'Nuevo proveedor',
          icon: Icons.person_add_alt_1_rounded,
          onPressed: () => _mostrarModalRegistro(context),
        ),
      ],
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
      // Móvil y desktop: filas de 2 para no alargar el sheet como un listado infinito
      final gap = compact ? const SizedBox(height: 8) : const SizedBox(height: 10);
      final gapW = compact ? 8.0 : 12.0;
      Widget pair(Widget a, Widget b) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              SizedBox(width: gapW),
              Expanded(child: b),
            ],
          );
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
            pair(
              AppTextField(
                label: 'RNC del Proveedor',
                controller: rncController,
              ),
              AppTextField(
                label: 'Persona de Contacto',
                controller: nombreContactoController,
              ),
            ),
            gap,
            AppTextField(
              label: 'Dirección',
              controller: direccionController,
            ),
            gap,
            pair(
              AppTextField(label: 'Ciudad', controller: ciudadController),
              AppTextField(
                label: 'Provincia',
                controller: provinciaController,
              ),
            ),
            gap,
            pair(
              AppTextField(label: 'Teléfono', controller: telefonoController),
              AppTextField(label: 'Celular', controller: celularController),
            ),
            gap,
            pair(
              AppTextField(label: 'WhatsApp', controller: whatsAppController),
              AppTextField(
                label: 'Correo Electrónico',
                controller: emailController,
              ),
            ),
            gap,
            pair(
              AppTextField(
                label: 'Límite de Crédito',
                controller: limiteCreditoController,
              ),
              AppTextField(
                label: 'Días de Crédito',
                controller: diasCreditoController,
              ),
            ),
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
                  maxHeight: (MediaQuery.sizeOf(ctx).height - bottom) * 0.78,
                  maxWidth: 560,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.storefront_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing
                                      ? 'Editar proveedor'
                                      : 'Nuevo proveedor',
                                  style: AppTypography.h4.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Información comercial y de contacto',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
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
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: formFields(compact: true),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
        final maxFormH = MediaQuery.sizeOf(ctx).height * 0.55;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: SizedBox(
            width: 620,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.storefront_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing
                                  ? 'Editar proveedor'
                                  : 'Nuevo proveedor',
                              style: AppTypography.h4.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Información comercial y de contacto',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
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
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: formFields(compact: false),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
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
