import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/creditos/presentation/providers/credito_providers.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

/// Modelos editables precargables (variables {{…}} se resuelven al imprimir).
class CreditoPlantillasModelo {
  CreditoPlantillasModelo._();

  static const solicitud = '''
Declaración del solicitante

Yo, {{CLIENTE}}, declaro que la información suministrada es verdadera y autorizo a {{EMPRESA}} (RNC {{RNC}}) a verificar mis datos y referencias para la evaluación del crédito correspondiente a la cotización {{NRO}}.

Monto de la operación: {{MONTO}}
Abono inicial: {{ABONO}}
Saldo a financiar: {{SALDO}}
Plazo propuesto: {{CUOTAS}} cuota(s) de {{CUOTA}} (estimado)

Me comprometo a cumplir las condiciones que se aprueben y consten en el contrato de crédito / compra a plazo.

Fecha: {{FECHA}}
''';

  static const contrato = '''
CONTRATO DE CRÉDITO / COMPRA A PLAZO

Entre {{EMPRESA}} (RNC {{RNC}}), en adelante EL ACREEDOR, y {{CLIENTE}}, en adelante EL DEUDOR, se conviene lo siguiente:

1. OBJETO Y MONTO
El DEUDOR adquiere los bienes/servicios de la cotización {{NRO}} por un valor de {{MONTO}}. Abono inicial: {{ABONO}}. Saldo a financiar: {{SALDO}}, pagadero en {{CUOTAS}} cuota(s) estimada(s) de {{CUOTA}}.

2. OBLIGACIONES DEL DEUDOR
a) Pagar puntualmente las cuotas en las fechas pactadas.
b) Informar cambios de domicilio o teléfono.
c) Conservar los bienes en buen estado mientras exista saldo pendiente.
d) Cubrir cargos por mora según la política del establecimiento, si aplica.

3. INCUMPLIMIENTO
El atraso en el pago podrá generar intereses moratorios y/o gestión de cobro conforme a la ley y a las políticas internas. El ACREEDOR se reserva las acciones legales pertinentes.

4. ACEPTACIÓN
Ambas partes declaran haber leído y aceptado este contrato en todas sus partes.

Fecha: {{FECHA}}
Dirección del acreedor: {{DIRECCION_EMPRESA}} · Tel: {{TELEFONO_EMPRESA}}
''';
}


class ConfigCreditoPage extends ConsumerStatefulWidget {
  const ConfigCreditoPage({super.key});

  static const String routeName = 'credito-config';
  static const String path = '/creditos/config';

  @override
  ConsumerState<ConfigCreditoPage> createState() => _ConfigCreditoPageState();
}

class _ConfigCreditoPageState extends ConsumerState<ConfigCreditoPage> {
  final _tasaCtrl = TextEditingController();
  final _cuotasCtrl = TextEditingController();
  final _plazoCtrl = TextEditingController();
  final _graciaCtrl = TextEditingController();
  final _moraCtrl = TextEditingController();
  final _plantillaSolCtrl = TextEditingController();
  final _plantillaConCtrl = TextEditingController();
  bool _cargado = false;
  bool _guardando = false;

  @override
  void dispose() {
    _tasaCtrl.dispose();
    _cuotasCtrl.dispose();
    _plazoCtrl.dispose();
    _graciaCtrl.dispose();
    _moraCtrl.dispose();
    _plantillaSolCtrl.dispose();
    _plantillaConCtrl.dispose();
    super.dispose();
  }

  void _llenarDesde(ParametroCreditoData p) {
    if (_cargado) return;
    _tasaCtrl.text = (p.tasaMensualDefault * 100).toStringAsFixed(2);
    _cuotasCtrl.text = '${p.cuotasDefault}';
    _plazoCtrl.text = '${p.plazoMaxMeses}';
    _graciaCtrl.text = '${p.diasGracia}';
    _moraCtrl.text = (p.moraPorcentaje * 100).toStringAsFixed(2);
    _plantillaSolCtrl.text = p.plantillaSolicitud;
    _plantillaConCtrl.text = p.plantillaContrato;
    _cargado = true;
  }


  void _cargarModeloSolicitud() {
    setState(() {
      _plantillaSolCtrl.text = CreditoPlantillasModelo.solicitud.trim();
    });
  }

  void _cargarModeloContrato() {
    setState(() {
      _plantillaConCtrl.text = CreditoPlantillasModelo.contrato.trim();
    });
  }

  void _limpiarSolicitud() {
    setState(() => _plantillaSolCtrl.clear());
  }

  void _limpiarContrato() {
    setState(() => _plantillaConCtrl.clear());
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final tasa =
          (double.tryParse(_tasaCtrl.text.replaceAll(',', '.')) ?? 0) / 100;
      final mora =
          (double.tryParse(_moraCtrl.text.replaceAll(',', '.')) ?? 0) / 100;
      await ref
          .read(parametrosCreditoDaoProvider)
          .guardar(
            tasaMensualDefault: tasa,
            cuotasDefault: int.tryParse(_cuotasCtrl.text) ?? 12,
            plazoMaxMeses: int.tryParse(_plazoCtrl.text) ?? 24,
            diasGracia: int.tryParse(_graciaCtrl.text) ?? 0,
            moraPorcentaje: mora,
            plantillaSolicitud: _plantillaSolCtrl.text.trim(),
            plantillaContrato: _plantillaConCtrl.text.trim(),
          );
      ref.invalidate(parametrosCreditoProvider);
      ref.invalidate(creditoDocumentoServiceProvider);
      if (!mounted) return;
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Configuración de crédito guardada'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(parametrosCreditoProvider);

    return AppScaffold(
      title: 'CONFIGURACIÓN CRÉDITO',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/creditos');
          }
        },
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (p) {
            _llenarDesde(p);
            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: AppLayout.centerConstrained(
                  maxWidth: MediaQuery.sizeOf(context).width < 768 ? 640 : 900,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        borderColor: AppColors.border,
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.tune_outlined,
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Parámetros de crédito',
                                    style: AppTypography.h4.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Valores por defecto y plantillas PDF',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.grey600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Parámetros',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Valores por defecto del área de crédito',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppCard(
                        borderColor: AppColors.border,
                        child: Column(
                          children: [
                            AppTextField(
                              label: 'Tasa mensual por defecto (%)',
                              controller: _tasaCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                            AppLayout.vM,
                            AppTextField(
                              label: 'Cuotas por defecto',
                              controller: _cuotasCtrl,
                              keyboardType: TextInputType.number,
                            ),
                            AppLayout.vM,
                            AppTextField(
                              label: 'Plazo máximo (meses)',
                              controller: _plazoCtrl,
                              keyboardType: TextInputType.number,
                            ),
                            AppLayout.vM,
                            AppTextField(
                              label: 'Días de gracia',
                              controller: _graciaCtrl,
                              keyboardType: TextInputType.number,
                            ),
                            AppLayout.vM,
                            AppTextField(
                              label: 'Mora mensual (%)',
                              controller: _moraCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Política interna; se refleja en textos',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppLayout.vL,
                      const SizedBox(height: 8),
                      Text(
                        'Plantilla solicitud',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cuerpo legal editable. Vacío = texto por defecto. Variables: {{EMPRESA}} {{RNC}} {{CLIENTE}} {{NRO}} {{MONTO}} {{ABONO}} {{SALDO}} {{CUOTAS}} {{CUOTA}} {{FECHA}}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppCard(
                        borderColor: AppColors.border,
                        child: TextField(
                          controller: _plantillaSolCtrl,
                          maxLines: 14,
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            labelText: 'Cuerpo completo de la solicitud',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _cargarModeloSolicitud,
                            icon: const Icon(Icons.description_outlined, size: 18),
                            label: const Text('Cargar modelo'),
                          ),
                          TextButton(
                            onPressed: _limpiarSolicitud,
                            child: const Text('Usar default del PDF'),
                          ),
                        ],
                      ),
                      AppLayout.vL,
                      const SizedBox(height: 8),
                      Text(
                        'Plantilla contrato',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cuerpo legal editable del contrato. Vacío = cláusulas por defecto. Mismas variables {{EMPRESA}} {{CLIENTE}} {{MONTO}}… El cronograma de cuotas se anexa automáticamente al PDF.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppCard(
                        borderColor: AppColors.border,
                        child: TextField(
                          controller: _plantillaConCtrl,
                          maxLines: 14,
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            labelText: 'Cuerpo completo del contrato',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _cargarModeloContrato,
                            icon: const Icon(Icons.description_outlined, size: 18),
                            label: const Text('Cargar modelo'),
                          ),
                          TextButton(
                            onPressed: _limpiarContrato,
                            child: const Text('Usar default del PDF'),
                          ),
                        ],
                      ),
                      AppLayout.vL,
                      AppButton(
                        text: 'GUARDAR CONFIGURACIÓN',
                        icon: Icons.save_outlined,
                        onPressed: _guardando ? null : _guardar,
                        isDisabled: _guardando,
                        isLoading: _guardando,
                        width: double.infinity,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
