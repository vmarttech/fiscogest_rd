import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_dropdown.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';

class ConfiguracionPage extends ConsumerStatefulWidget {
  const ConfiguracionPage({super.key});
  static const String routeName = 'configuracion';

  @override
  ConsumerState<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends ConsumerState<ConfiguracionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController(text: 'VmartTech');
  final _rncController = TextEditingController(text: '00500468376');
  final _itbisController = TextEditingController(text: '18.0');
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  String _monedaSeleccionada = 'DOP';
  String _idiomaSeleccionado = 'Español';
  String? _logoPath;

  @override
  void dispose() {
    _nombreController.dispose();
    _rncController.dispose();
    _itbisController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  bool _validarFormulario() {
    final nombre = _nombreController.text.trim();
    final rnc = _rncController.text.trim();
    final itbis = double.tryParse(_itbisController.text.trim());
    final correo = _correoController.text.trim();

    if (nombre.isEmpty || nombre.length > 120) return false;
    if (rnc.isEmpty || rnc.length < 9 || rnc.length > 13) return false;
    if (itbis == null || itbis < 0 || itbis > 100) return false;
    if (correo.isNotEmpty && !RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(correo)) return false;

    return true;
  }

  void _guardarConfiguracion() {
    if (!_formKey.currentState!.validate() || !_validarFormulario()) return;

    try {
      // Aquí conectar con el provider para persistir
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Configuración guardada exitosamente'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.allM),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final formValido = _validarFormulario();

    return AppScaffold(
      title: 'Configuración Global',
      subtitle: 'Parámetros fiscales, identidad corporativa y preferencias del sistema',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: const [],
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 24,
            isMobile ? 16 : 20,
            isMobile ? 16 : 24,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Form(
                key: _formKey,
                child: isMobile
                    ? Column(
                        children: [
                          _buildTarjetaIdentidad(),
                          AppLayout.vL,
                          _buildTarjetaParametros(),
                          AppLayout.vL,
                          _buildBotonGuardar(formValido),
                        ],
                      )
                    : Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox.shrink(),
                              _buildBotonGuardar(formValido),
                            ],
                          ),
                          AppLayout.vL,
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: _buildTarjetaIdentidad()),
                              AppLayout.hL,
                              Expanded(flex: 2, child: _buildTarjetaParametros()),
                            ],
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

  Widget _buildBotonGuardar(bool valido) {
    return AbsorbPointer(
      absorbing: !valido,
      child: Opacity(
        opacity: valido ? 1.0 : 0.5,
        child: AppButton(
          text: 'Guardar Cambios',
          icon: Icons.save_outlined,
          onPressed: _guardarConfiguracion,
        ),
      ),
    );
  }

  Widget _buildTarjetaIdentidad() {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.business_center_outlined, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text('Identidad Comercial y Fiscal', style: AppTypography.h3),
            ],
          ),
          const Divider(height: 32, color: AppColors.grey200),
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: AppRadius.allM,
                  border: Border.all(color: AppColors.grey200),
                ),
                child: _logoPath != null
                    ? const Icon(Icons.image, color: AppColors.primary, size: 36)
                    : const Icon(Icons.store_mall_directory_outlined,
                        color: AppColors.textSecondary, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Logotipo del Negocio', style: AppTypography.labelMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Formato PNG o JPG recomendado (Máx 2MB)',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _logoPath = 'logo_placeholder.png'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.grey200),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.allS),
                        ),
                        icon: const Icon(Icons.upload_file, size: 16),
                        label: const Text('Cambiar Logo', style: AppTypography.labelMedium),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FormField<String>(
            initialValue: _nombreController.text,
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return 'Ingrese el nombre comercial';
              if (v.length > 120) return 'Máximo 120 caracteres';
              return null;
            },
            builder: (field) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Nombre Comercial / Razón Social *',
                  hint: 'Ej. Almacenes Comerciales RD, S.A.',
                  controller: _nombreController,
                  prefixIcon: Icons.storefront,
                  onChanged: (_) => field.didChange(_nombreController.text),
                ),
                if (field.hasError) _buildErrorText(field.errorText!),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FormField<String>(
            initialValue: _rncController.text,
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return 'Ingrese RNC o Cédula';
              if (v.length < 9 || v.length > 13) return 'Debe tener entre 9 y 13 dígitos';
              return null;
            },
            builder: (field) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'RNC o Cédula de Identidad *',
                  hint: 'Ej. 00500468376',
                  controller: _rncController,
                  prefixIcon: Icons.badge_outlined,
                  onChanged: (_) => field.didChange(_rncController.text),
                ),
                if (field.hasError) _buildErrorText(field.errorText!),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Dirección Física del Establecimiento',
            hint: 'Ej. Av. Principal #123, Santo Domingo',
            controller: _direccionController,
            prefixIcon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (_, constraints) => constraints.maxWidth < 500
                ? Column(
                    children: [
                      AppTextField(
                        label: 'Teléfono de Contacto',
                        hint: 'Ej. 809-000-0000',
                        controller: _telefonoController,
                        prefixIcon: Icons.phone_outlined,
                      ),
                      const SizedBox(height: 16),
                      FormField<String>(
                        initialValue: _correoController.text,
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isNotEmpty && !RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(v)) {
                            return 'Ingrese un correo válido';
                          }
                          return null;
                        },
                        builder: (field) => Column(
                          children: [
                            AppTextField(
                              label: 'Correo Electrónico',
                              hint: 'Ej. contacto@negocio.com',
                              controller: _correoController,
                              prefixIcon: Icons.email_outlined,
                              onChanged: (_) => field.didChange(_correoController.text),
                            ),
                            if (field.hasError) _buildErrorText(field.errorText!),
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Teléfono de Contacto',
                          hint: 'Ej. 809-000-0000',
                          controller: _telefonoController,
                          prefixIcon: Icons.phone_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FormField<String>(
                          initialValue: _correoController.text,
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isNotEmpty && !RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(v)) {
                              return 'Correo inválido';
                            }
                            return null;
                          },
                          builder: (field) => Column(
                            children: [
                              AppTextField(
                                label: 'Correo Electrónico',
                                hint: 'Ej. contacto@negocio.com',
                                controller: _correoController,
                                prefixIcon: Icons.email_outlined,
                                onChanged: (_) => field.didChange(_correoController.text),
                              ),
                              if (field.hasError) _buildErrorText(field.errorText!),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          FormField<String>(
            initialValue: _itbisController.text,
            validator: (value) {
              final v = value?.trim() ?? '';
              final num = double.tryParse(v);
              if (v.isEmpty || num == null) return 'Ingrese un valor numérico';
              if (num < 0 || num > 100) return 'Debe estar entre 0 y 100';
              return null;
            },
            builder: (field) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Impuesto por Defecto (ITBIS %) *',
                  hint: '18.0',
                  controller: _itbisController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.percent,
                  onChanged: (_) => field.didChange(_itbisController.text),
                ),
                if (field.hasError) _buildErrorText(field.errorText!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaParametros() {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_outlined, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text('Parámetros Regionales', style: AppTypography.h3),
            ],
          ),
          const Divider(height: 32, color: AppColors.grey200),
          const Text('Moneda Oficial', style: AppTypography.labelMedium),
          const SizedBox(height: 8),
          AppDropdown<String>(
            initialValue: _monedaSeleccionada,
            label: 'Moneda',
            items: const [
              DropdownMenuItem(value: 'DOP', child: Text('Peso Dominicano (DOP)')),
              DropdownMenuItem(value: 'USD', child: Text('Dólar Estadounidense (USD)')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _monedaSeleccionada = val);
            },
          ),
          const SizedBox(height: 20),
          const Text('Idioma del Sistema', style: AppTypography.labelMedium),
          const SizedBox(height: 8),
          AppDropdown<String>(
            initialValue: _idiomaSeleccionado,
            label: 'Idioma',
            items: const [
              DropdownMenuItem(value: 'Español', child: Text('Español')),
              DropdownMenuItem(value: 'English', child: Text('English')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _idiomaSeleccionado = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorText(String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 12),
      child: Text(
        texto,
        style: AppTypography.bodySmall.copyWith(color: AppColors.error),
      ),
    );
  }
}
