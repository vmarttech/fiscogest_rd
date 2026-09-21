import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_completo_providers.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_completo.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';

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
    _nombreController = TextEditingController(text: widget.cliente?.nombre ?? '');
    _direccionController = TextEditingController(text: widget.cliente?.direccion ?? '');
    _telefonoController = TextEditingController(text: widget.cliente?.telefono ?? '');
    _correoController = TextEditingController(text: widget.cliente?.correo ?? '');
    _rncCedulaController = TextEditingController(text: widget.cliente?.rncCedula ?? '');
    _observacionesController = TextEditingController(text: widget.cliente?.observaciones ?? '');
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
      historial: widget.cliente?.historial ?? 'Cliente registrado en el sistema.',
    );
    try {
      if (_esEdicion) {
        ref.read(clienteCompletoControllerProvider.notifier).actualizar(cli);
      } else {
        ref.read(clienteCompletoControllerProvider.notifier).guardar(cli);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.white),
              AppLayout.hM,
              Text('Cliente ${_esEdicion ? 'actualizado' : 'registrado'} correctamente'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    return AppScaffold(
      title: _esEdicion ? 'Editar Cliente' : 'Nuevo Cliente',
      subtitle: _esEdicion
          ? 'Modificar datos del cliente'
          : 'Registro de datos personales, fiscales y contacto',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      actions: const [],
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 24,
            isMobile ? 16 : 20,
            isMobile ? 16 : 24,
            24,
          ),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Datos Principales', style: AppTypography.h4),
                    AppLayout.vS,
                    if (isMobile) ...[
                      FormField<String>(
                        initialValue: _nombreController.text,
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Ingrese el nombre' : null,
                        builder: (formFieldState) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextField(
                              label: 'Nombre / Razón Social *',
                              hint: 'Ej. Colmado Mendoza o Juan Pérez',
                              controller: _nombreController,
                              onChanged: (_) => formFieldState.didChange(_nombreController.text),
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
                        initialValue: _rncCedulaController.text,
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Ingrese el RNC o Cédula' : null,
                        builder: (formFieldState) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextField(
                              label: 'RNC o Cédula *',
                              hint: 'Ej. 00112345678',
                              controller: _rncCedulaController,
                              onChanged: (_) => formFieldState.didChange(_rncCedulaController.text),
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
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: FormField<String>(
                              initialValue: _nombreController.text,
                              validator: (value) => value == null || value.trim().isEmpty
                                  ? 'Ingrese el nombre'
                                  : null,
                              builder: (formFieldState) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppTextField(
                                    label: 'Nombre / Razón Social *',
                                    hint: 'Ej. Colmado Mendoza o Juan Pérez',
                                    controller: _nombreController,
                                    onChanged: (_) => formFieldState.didChange(_nombreController.text),
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
                          ),
                          AppLayout.hM,
                          Expanded(
                            child: FormField<String>(
                              initialValue: _rncCedulaController.text,
                              validator: (value) => value == null || value.trim().isEmpty
                                  ? 'Ingrese el RNC o Cédula'
                                  : null,
                              builder: (formFieldState) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppTextField(
                                    label: 'RNC o Cédula *',
                                    hint: 'Ej. 00112345678',
                                    controller: _rncCedulaController,
                                    onChanged: (_) =>
                                        formFieldState.didChange(_rncCedulaController.text),
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
                          ),
                        ],
                      ),
                    ],
                    AppLayout.vM,
                    if (isMobile) ...[
                      FormField<String>(
                        initialValue: _telefonoController.text,
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Ingrese el teléfono' : null,
                        builder: (formFieldState) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextField(
                              label: 'Teléfono / Celular *',
                              hint: '809-000-0000',
                              controller: _telefonoController,
                              onChanged: (_) => formFieldState.didChange(_telefonoController.text),
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
                        initialValue: _correoController.text,
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Ingrese el correo' : null,
                        builder: (formFieldState) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextField(
                              label: 'Correo Electrónico *',
                              hint: 'correo@ejemplo.com',
                              controller: _correoController,
                              onChanged: (_) => formFieldState.didChange(_correoController.text),
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
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: FormField<String>(
                              initialValue: _telefonoController.text,
                              validator: (value) => value == null || value.trim().isEmpty
                                  ? 'Ingrese el teléfono'
                                  : null,
                              builder: (formFieldState) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppTextField(
                                    label: 'Teléfono / Celular *',
                                    hint: '809-000-0000',
                                    controller: _telefonoController,
                                    onChanged: (_) =>
                                        formFieldState.didChange(_telefonoController.text),
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
                          ),
                          AppLayout.hM,
                          Expanded(
                            child: FormField<String>(
                              initialValue: _correoController.text,
                              validator: (value) => value == null || value.trim().isEmpty
                                  ? 'Ingrese el correo'
                                  : null,
                              builder: (formFieldState) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppTextField(
                                    label: 'Correo Electrónico *',
                                    hint: 'correo@ejemplo.com',
                                    controller: _correoController,
                                    onChanged: (_) => formFieldState.didChange(_correoController.text),
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
                          ),
                        ],
                      ),
                    ],
                    AppLayout.vL,
                    const Divider(height: 1, color: AppColors.grey200),
                    AppLayout.vM,
                    const Text('Ubicación', style: AppTypography.h4),
                    AppLayout.vS,
                    AppTextField(
                      label: 'Dirección',
                      hint: 'Calle Principal #12, Sector...',
                      controller: _direccionController,
                    ),
                    AppLayout.vL,
                    const Divider(height: 1, color: AppColors.grey200),
                    AppLayout.vM,
                    const Text('Observaciones', style: AppTypography.h4),
                    AppLayout.vS,
                    SizedBox(
                      height: 100,
                      child: AppTextField(
                        label: 'Comentarios adicionales',
                        hint: 'Referencias, condiciones especiales...',
                        controller: _observacionesController,
                      ),
                    ),
                    AppLayout.vL,
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        text: _esEdicion ? 'Actualizar Cliente' : 'Guardar Cliente',
                        icon: Icons.save_rounded,
                        onPressed: _guardar,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
