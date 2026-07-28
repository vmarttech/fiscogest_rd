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

class ClientesPage extends ConsumerStatefulWidget {
  const ClientesPage({super.key});

  @override
  ConsumerState<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends ConsumerState<ClientesPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _establecimientoController = TextEditingController();
  final _rncController = TextEditingController();

  String _tipoComprobanteSeleccionado = 'B02 - Consumidor Final';

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _establecimientoController.dispose();
    _rncController.dispose();
    super.dispose();
  }

  void _guardarCliente() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              AppLayout.hM,
              Text('Cliente registrado correctamente en el sistema'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.allM),
          margin: AppSpacing.allM,
        ),
      );
      _formKey.currentState!.reset();
      _rncController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    const bool esModoCompleto = true;

    return AppScaffold(
      body: SingleChildScrollView(
        padding: AppSpacing.hL.copyWith(top: AppSpacing.l, bottom: AppSpacing.l),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Directorio de Clientes y Negocios',
                          style: AppTypography.h1,
                        ),
                        AppLayout.vXs,
                        Text(
                          'Gestión unificada para comercios locales y contribuyentes con control fiscal.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Container(
                      padding: AppSpacing.hS.copyWith(top: AppSpacing.xs, bottom: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: AppRadius.allL,
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
                          AppLayout.hS,
                          Text(
                            'Modo Unificado Activo',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppLayout.vL,

                AppCard(
                  padding: AppSpacing.allL,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_outline, color: AppColors.primary, size: 22),
                            AppLayout.hS,
                            Text(
                              'Información General',
                              style: AppTypography.h3,
                            ),
                          ],
                        ),
                        AppLayout.vM,
                        AppTextField(
                          label: 'Nombre / Razón Social / Negocio *',
                          hint: 'Ej. Colmado Mendoza o Juan Pérez',
                          controller: _nombreController,
                        ),
                        AppLayout.vM,
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Teléfono / Celular',
                                hint: '809-000-0000',
                                controller: _telefonoController,
                              ),
                            ),
                            AppLayout.hM,
                            Expanded(
                              child: AppTextField(
                                label: 'Tipo de Establecimiento',
                                hint: 'Colmado, Salón, Barbería...',
                                controller: _establecimientoController,
                              ),
                            ),
                          ],
                        ),
                        AppLayout.vM,
                        AppTextField(
                          label: 'Dirección o Sector',
                          hint: 'Calle Principal #12, Sector...',
                          controller: _direccionController,
                        ),

                        if (esModoCompleto) ...[
                          AppLayout.vL,
                          const Divider(height: 1, color: AppColors.grey200),
                          AppLayout.vM,
                          const Row(
                            children: [
                              Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 22),
                              AppLayout.hS,
                              Text(
                                'Información Fiscal y Tributaria (DGII)',
                                style: AppTypography.h3,
                              ),
                            ],
                          ),
                          AppLayout.vM,
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'RNC o Cédula',
                                  hint: 'Ej. 00112345678',
                                  controller: _rncController,
                                ),
                              ),
                              AppLayout.hM,
                              Expanded(
                                child: AppDropdown<String>(
                                  label: 'Tipo de Comprobante',
                                  initialValue: _tipoComprobanteSeleccionado,
                                  items: const [
                                    DropdownMenuItem(value: 'B01 - Crédito Fiscal', child: Text('B01 - Crédito Fiscal')),
                                    DropdownMenuItem(value: 'B02 - Consumidor Final', child: Text('B02 - Consumidor Final')),
                                    DropdownMenuItem(value: 'B14 - Regímenes Especiales', child: Text('B14 - Regímenes Especiales')),
                                  ],
                                  onChanged: (String? val) {
                                    if (val != null) {
                                      setState(() => _tipoComprobanteSeleccionado = val);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],

                        AppLayout.vL,

                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            text: 'Guardar Cliente en el Sistema',
                            icon: Icons.save_rounded,
                            onPressed: _guardarCliente,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
