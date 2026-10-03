import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_completo_providers.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_completo.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

class NuevoClientePage extends ConsumerStatefulWidget {
  const NuevoClientePage({super.key, this.cliente});

  static const String routeName = 'nuevo-cliente';
  static const String editRouteName = 'editar-cliente';

  final ClienteCompleto? cliente;

  @override
  ConsumerState<NuevoClientePage> createState() => _NuevoClientePageState();
}

class _NuevoClientePageState extends ConsumerState<NuevoClientePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _direccionController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _correoController;
  late final TextEditingController _rncCedulaController;
  late final TextEditingController _observacionesController;

  bool get _esEdicion => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.cliente?.nombre ?? '',
    );
    _direccionController = TextEditingController(
      text: widget.cliente?.direccion ?? '',
    );
    _telefonoController = TextEditingController(
      text: widget.cliente?.telefono ?? '',
    );
    _correoController = TextEditingController(
      text: widget.cliente?.correo ?? '',
    );
    _rncCedulaController = TextEditingController(
      text: widget.cliente?.rncCedula ?? '',
    );
    _observacionesController = TextEditingController(
      text: widget.cliente?.observaciones ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _rncCedulaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    final cli = ClienteCompleto(
      id: widget.cliente?.id,
      nombre: _nombreController.text.trim(),
      direccion: _direccionController.text.trim(),
      telefono: _telefonoController.text.trim(),
      correo: _correoController.text.trim(),
      rncCedula: _rncCedulaController.text.trim(),
      observaciones: _observacionesController.text.trim(),
      historial:
          widget.cliente?.historial ?? 'Cliente registrado en el sistema.',
    );

    try {
      if (_esEdicion) {
        ref.read(clienteCompletoControllerProvider.notifier).actualizar(cli);
      } else {
        ref.read(clienteCompletoControllerProvider.notifier).guardar(cli);
      }
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(
            'Cliente ${_esEdicion ? 'actualizado' : 'registrado'} correctamente',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  InputDecoration _deco(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.6)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final accionGuardar = SizedBox(
      width: mobile ? double.infinity : 240,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _guardar,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.save_rounded, size: 20),
        label: Text(
          _esEdicion ? 'ACTUALIZAR' : 'GUARDAR CLIENTE',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );

    return AppScaffold(
      title: _esEdicion ? 'EDITAR CLIENTE' : 'NUEVO CLIENTE',
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  mobile ? 16 : 24,
                  mobile ? 12 : 16,
                  mobile ? 16 : 24,
                  16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: mobile ? 640 : 900),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _esEdicion
                                ? 'Modificar datos del cliente'
                                : 'Registro de datos y contacto',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _SeccionCard(
                            titulo: 'Datos principales',
                            icon: Icons.person_outline,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nombreController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: _deco(
                                    'Nombre / Razón social *',
                                    hint: 'Ej. Juan Pérez',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Ingrese el nombre'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                if (mobile) ...[
                                  TextFormField(
                                    controller: _rncCedulaController,
                                    decoration: _deco(
                                      'RNC o cédula',
                                      hint: '00112345678',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _telefonoController,
                                    keyboardType: TextInputType.phone,
                                    decoration: _deco(
                                      'Teléfono / celular *',
                                      hint: '809-000-0000',
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'Ingrese el teléfono'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _correoController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: _deco(
                                      'Correo',
                                      hint: 'correo@ejemplo.com',
                                    ),
                                  ),
                                ] else ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _rncCedulaController,
                                          decoration: _deco(
                                            'RNC o cédula',
                                            hint: '00112345678',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _telefonoController,
                                          keyboardType: TextInputType.phone,
                                          decoration: _deco(
                                            'Teléfono / celular *',
                                            hint: '809-000-0000',
                                          ),
                                          validator: (v) =>
                                              (v == null || v.trim().isEmpty)
                                              ? 'Ingrese el teléfono'
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _correoController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: _deco(
                                      'Correo',
                                      hint: 'correo@ejemplo.com',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SeccionCard(
                            titulo: 'Ubicación',
                            icon: Icons.place_outlined,
                            child: TextFormField(
                              controller: _direccionController,
                              decoration: _deco(
                                'Dirección',
                                hint: 'Calle, sector…',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SeccionCard(
                            titulo: 'Observaciones',
                            icon: Icons.notes_outlined,
                            child: TextFormField(
                              controller: _observacionesController,
                              maxLines: 3,
                              decoration: _deco(
                                'Comentarios',
                                hint: 'Referencias, condiciones…',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (mobile)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: const Border(top: BorderSide(color: AppColors.border)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(top: false, child: accionGuardar),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                child: SafeArea(
                  top: false,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: accionGuardar,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SeccionCard extends StatelessWidget {
  const _SeccionCard({
    required this.titulo,
    required this.icon,
    required this.child,
  });

  final String titulo;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
