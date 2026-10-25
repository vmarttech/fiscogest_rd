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
    // Ficha técnica FiscoGest — Proveedores (sin desviaciones)
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final proveedoresAsync = ref.watch(proveedorControllerProvider);

    const cBg = Color(0xFFEEF2F3);
    const cWhite = Color(0xFFFFFFFF);
    const cMuted = Color(0xFF1E293B);
    const cInk = Color(0xFF0F172A);
    const cTealDark = Color(0xFF114E54);
    const cMint = Color(0xFF114E54);
    const cAvatarBg = Color(0xFFE5F2F3);
    const cBorder = Color(0xFFE2E8F0);
    const cHeaderBg = Color(0xFFFAFAFA);

    return AppScaffold(
      title: 'Proveedores',
      subtitle: 'Directorio de proveedores y contactos',
      backgroundColor: cBg,
      // PC: sin barra del módulo. Móvil: sí.
      showAppBar: isMobile,
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
                  // Cabecera: título | buscador compacto der | Nuevo
                  if (!isMobile)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Proveedores',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: cInk,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Gestiona tus proveedores y contactos comerciales',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: cMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Buscador reducido a la derecha
                          SizedBox(
                            width: 280,
                            height: 44,
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(
                                () =>
                                    _filtroBusqueda = value.toLowerCase(),
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: cInk,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Buscar proveedor...',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: cMuted,
                                ),
                                isDense: true,
                                filled: true,
                                fillColor: cWhite,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: cBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: cBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: cMint,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () =>
                                _mostrarModalRegistro(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: cMint,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text(
                              'Nuevo Proveedor',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: () => _mostrarModalRegistro(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: cMint,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text(
                            'Nuevo Proveedor',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(
                        () => _filtroBusqueda = value.toLowerCase(),
                      ),
                      style: const TextStyle(fontSize: 14, color: cInk),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, RNC o correo...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: cMuted,
                        ),
                        filled: true,
                        fillColor: cWhite,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: cBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: cBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: cMint, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (!isMobile) const SizedBox(height: 16),
                  Expanded(
                    child: proveedoresAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: cMint),
                      ),
                      error: (e, _) => Center(
                        child: Text(
                          'Error: $e',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                      data: (proveedores) {
                        final filtrados = proveedores.where((p) {
                          final nombre = p.nombreEmpresa.toLowerCase();
                          final rnc = (p.rnc ?? '').toLowerCase();
                          final contacto =
                              (p.nombreContacto ?? '').toLowerCase();
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
                                      color: cAvatarBg,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.store_mall_directory_outlined,
                                      size: 32,
                                      color: cTealDark,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _filtroBusqueda.isEmpty
                                        ? 'Sin proveedores aún'
                                        : 'Sin resultados',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: cInk,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _filtroBusqueda.isEmpty
                                        ? 'Registra el primer proveedor\npara compras y cuentas por pagar.'
                                        : 'Prueba con otro término de búsqueda.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: cMuted,
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
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final proveedor = filtrados[i];
                              return _ProveedorCardMobile(
                                proveedor: proveedor,
                                onEdit: () => _mostrarModalRegistro(
                                  context,
                                  proveedorToEdit: proveedor,
                                ),
                                onDelete: () => _confirmarEliminarProveedor(
                                  context,
                                  proveedor,
                                ),
                                onSettings: () =>
                                    _abrirConfiguracionProveedor(
                                  context,
                                  proveedor,
                                ),
                              );
                            },
                          );
                        }

                        // DESKTOP: tabla ficha técnica
                        return Container(
                          decoration: BoxDecoration(
                            color: cWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cBorder),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0F000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                decoration: const BoxDecoration(
                                  color: cHeaderBg,
                                  border: Border(
                                    bottom: BorderSide(color: cBorder),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    SizedBox(width: 48),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'PROVEEDOR',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: cMuted,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'CONTACTO',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: cMuted,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'CORREO / TEL',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: cMuted,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        'ACCIONES',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: cMuted,
                                          letterSpacing: 0.6,
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
                                    color: cBorder,
                                  ),
                                  itemBuilder: (_, i) {
                                    final proveedor = filtrados[i];
                                    return Material(
                                      color: cWhite,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 14,
                                        ),
                                        child: Row(
                                          children: [
                                            // Avatar
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: cAvatarBg,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.business_rounded,
                                                color: cTealDark,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Proveedor
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    proveedor.nombreEmpresa,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: cInk,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'RNC ${proveedor.rnc ?? '—'}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: cMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Contacto
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                proveedor.nombreContacto
                                                            ?.isNotEmpty ==
                                                        true
                                                    ? proveedor.nombreContacto!
                                                    : '—',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: cInk,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            // Correo / Tel
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    proveedor.email
                                                                ?.isNotEmpty ==
                                                            true
                                                        ? proveedor.email!
                                                        : '—',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: cInk,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    proveedor.telefono
                                                                ?.isNotEmpty ==
                                                            true
                                                        ? proveedor.telefono!
                                                        : (proveedor.celular
                                                                    ?.isNotEmpty ==
                                                                true
                                                            ? proveedor
                                                                .celular!
                                                            : '—'),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: cMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Acciones: editar · eliminar · configurar
                                            SizedBox(
                                              width: 120,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  _ProvActionIcon(
                                                    Icons.edit_outlined,
                                                    cMuted,
                                                    () =>
                                                        _mostrarModalRegistro(
                                                      context,
                                                      proveedorToEdit:
                                                          proveedor,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  _ProvActionIcon(
                                                    Icons.delete_outline,
                                                    AppColors.error,
                                                    () =>
                                                        _confirmarEliminarProveedor(
                                                      context,
                                                      proveedor,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  _ProvActionIcon(
                                                    Icons.settings_outlined,
                                                    cMuted,
                                                    () =>
                                                        _abrirConfiguracionProveedor(
                                                      context,
                                                      proveedor,
                                                    ),
                                                  ),
                                                ],
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
              ref
                  .read(proveedorControllerProvider.notifier)
                  .eliminar(proveedor.id!);
            }
            Navigator.pop(context);
          },
        ),
      ],
    );
  }


  void _abrirConfiguracionProveedor(
    BuildContext context,
    Proveedor proveedor,
  ) {
    final limiteCtrl = TextEditingController(
      text: proveedor.limiteCredito > 0
          ? proveedor.limiteCredito.toStringAsFixed(2)
          : '',
    );
    final diasCtrl = TextEditingController(
      text: proveedor.diasCredito > 0 ? '${proveedor.diasCredito}' : '',
    );
    final condicionesCtrl = TextEditingController(
      text: proveedor.condicionesNota ?? '',
    );
    var estado = proveedor.estado;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Configurar · ${proveedor.nombreEmpresa}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Límite de crédito, días y condiciones',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: limiteCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Límite de crédito (RD\$)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: diasCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Días de crédito',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: condicionesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Condiciones / notas',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue:
                          estado == 'Inactivo' ? 'Inactivo' : 'Activo',
                      decoration: InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Activo',
                          child: Text('Activo'),
                        ),
                        DropdownMenuItem(
                          value: 'Inactivo',
                          child: Text('Inactivo'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setModal(() => estado = v);
                      },
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () {
                        final actualizado = proveedor.copyWith(
                          limiteCredito:
                              double.tryParse(limiteCtrl.text.trim()) ?? 0,
                          diasCredito:
                              int.tryParse(diasCtrl.text.trim()) ?? 0,
                          condicionesNota: condicionesCtrl.text.trim().isEmpty
                              ? null
                              : condicionesCtrl.text.trim(),
                          estado: estado,
                          fechaActualizacion: DateTime.now(),
                        );
                        ref
                            .read(proveedorControllerProvider.notifier)
                            .actualizar(actualizado);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Configuración de ${proveedor.nombreEmpresa} guardada',
                            ),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF114E54),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Guardar configuración',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
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
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }

    Widget formFields({required bool compact}) {
      // Móvil y desktop: filas de 2 para no alargar el sheet como un listado infinito
      final gap = compact
          ? const SizedBox(height: 8)
          : const SizedBox(height: 10);
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
            AppTextField(label: 'Dirección', controller: direccionController),
            gap,
            pair(
              AppTextField(label: 'Ciudad', controller: ciudadController),
              AppTextField(label: 'Provincia', controller: provinciaController),
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
                                      color: const Color(0xFF1E293B),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 24,
          ),
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
                                color: const Color(0xFF1E293B),
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


class _ProvActionIcon extends StatelessWidget {
  const _ProvActionIcon(this.icon, this.color, this.onTap);
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _ProveedorCardMobile extends StatelessWidget {
  const _ProveedorCardMobile({
    required this.proveedor,
    required this.onEdit,
    required this.onDelete,
    required this.onSettings,
  });

  final Proveedor proveedor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    const cWhite = Color(0xFFFFFFFF);
    const cMuted = Color(0xFF1E293B);
    const cInk = Color(0xFF0F172A);
    const cTealDark = Color(0xFF114E54);
    const cAvatarBg = Color(0xFFE5F2F3);
    const cBorder = Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 3),
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
                  color: cAvatarBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: cTealDark,
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cInk,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'RNC ${proveedor.rnc ?? '—'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: cMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: cBorder),
          const SizedBox(height: 12),
          _mRow(Icons.person_outline, 'Contacto',
              proveedor.nombreContacto?.isNotEmpty == true
                  ? proveedor.nombreContacto!
                  : '—'),
          const SizedBox(height: 8),
          _mRow(Icons.email_outlined, 'Correo',
              proveedor.email?.isNotEmpty == true ? proveedor.email! : '—'),
          const SizedBox(height: 8),
          _mRow(
            Icons.phone_outlined,
            'Teléfono',
            proveedor.telefono?.isNotEmpty == true
                ? proveedor.telefono!
                : (proveedor.celular?.isNotEmpty == true
                    ? proveedor.celular!
                    : '—'),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cTealDark,
                    side: const BorderSide(color: cBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                height: 40,
                child: OutlinedButton(
                  onPressed: onSettings,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cMuted,
                    side: const BorderSide(color: cBorder),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(Icons.settings_outlined, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                height: 40,
                child: OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: cBorder),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(Icons.delete_outline, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1E293B)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
