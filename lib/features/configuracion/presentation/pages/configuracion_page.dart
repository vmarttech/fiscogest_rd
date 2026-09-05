import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_dropdown.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';

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

  void _guardarConfiguracion() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.white),
              AppLayout.hM,
              Text('Configuración guardada exitosamente'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.allM),
          margin: AppSpacing.allM,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final anchoPantalla = MediaQuery.of(context).size.width;
    final pantallaPequena = anchoPantalla < 900;

    return AppScaffold(
      title: 'Configuración Global',
      padding: AppSpacing.hL.copyWith(top: AppSpacing.l, bottom: AppSpacing.l),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configuración Global',
                          style: AppTypography.h2.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        AppLayout.vS,
                        Text(
                          'Parámetros fiscales, identidad corporativa y preferencias del sistema.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    AppButton(
                      text: 'Guardar Cambios',
                      icon: Icons.save_outlined,
                      onPressed: _guardarConfiguracion,
                    ),
                  ],
                ),
                AppLayout.vL,
                Form(
                  key: _formKey,
                  child: pantallaPequena
                      ? Column(
                          children: [
                            _buildTarjetaIdentidad(),
                            AppLayout.vL,
                            _buildTarjetaParametros(),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildTarjetaIdentidad()),
                            AppLayout.hL,
                            Expanded(flex: 2, child: _buildTarjetaParametros()),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTarjetaIdentidad() {
    return AppCard(
      padding: AppSpacing.allL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.business_center_outlined,
                  color: AppColors.primary, size: 22),
              AppLayout.hS,
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
              AppLayout.hM,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Logotipo del Negocio',
                        style: AppTypography.labelMedium),
                    AppLayout.vXs,
                    Text('Formato PNG o JPG recomendado (Máx 2MB)',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    AppLayout.vS,
                    SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _logoPath = 'logo_placeholder.png'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.grey200),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.allS,
                          ),
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
          AppLayout.vM,
          AppTextField(
            label: 'Nombre Comercial / Razón Social',
            hint: 'Ej. Almacenes Comerciales RD, S.A.',
            controller: _nombreController,
            prefixIcon: Icons.storefront,
          ),
          AppLayout.vM,
          AppTextField(
            label: 'RNC o Cédula de Identidad',
            hint: 'Ej. 131-00000-1',
            controller: _rncController,
            prefixIcon: Icons.badge_outlined,
          ),
          AppLayout.vM,
          AppTextField(
            label: 'Dirección Física del Establecimiento',
            hint: 'Ej. Av. Principal #123, Santo Domingo',
            controller: _direccionController,
            prefixIcon: Icons.location_on_outlined,
          ),
          AppLayout.vM,
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
                      AppLayout.vM,
                      AppTextField(
                        label: 'Correo Electrónico',
                        hint: 'Ej. contacto@negocio.com',
                        controller: _correoController,
                        prefixIcon: Icons.email_outlined,
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
                      AppLayout.hM,
                      Expanded(
                        child: AppTextField(
                          label: 'Correo Electrónico',
                          hint: 'Ej. contacto@negocio.com',
                          controller: _correoController,
                          prefixIcon: Icons.email_outlined,
                        ),
                      ),
                    ],
                  ),
          ),
          AppLayout.vM,
          AppTextField(
            label: 'Impuesto por Defecto (ITBIS %)',
            hint: '18.0',
            controller: _itbisController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icons.percent,
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaParametros() {
    return AppCard(
      padding: AppSpacing.allL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_outlined, color: AppColors.primary, size: 22),
              AppLayout.hS,
              Text('Parámetros Regionales', style: AppTypography.h3),
            ],
          ),
          const Divider(height: 32, color: AppColors.grey200),
          const Text('Moneda Oficial', style: AppTypography.labelMedium),
          AppLayout.vS,
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
          AppLayout.vM,
          const Text('Idioma del Sistema', style: AppTypography.labelMedium),
          AppLayout.vS,
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
}
