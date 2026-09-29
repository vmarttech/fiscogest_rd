import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_hub_hero.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/features/creditos/domain/services/calculadora_credito_service.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/plan_pago.dart';

/// Simulación rápida. Motor: [CalculadoraCreditoService] (igual que crédito formal).
/// Tasa oculta. Plazo y cuotas: mismas opciones que formulario_credito_dialog.
class SimuladorCreditoPage extends StatefulWidget {
  const SimuladorCreditoPage({super.key});

  static const String path = '/ventas/simulador-credito';
  static const String routeName = 'simulador-credito';

  static const List<int> opcionesPlazo = [1, 2, 3, 6];
  static const List<int> opcionesCuotas = [1, 2, 3, 6];
  static const double tasaMensualDefault = 0.05;

  @override
  State<SimuladorCreditoPage> createState() => _SimuladorCreditoPageState();
}

class _SimuladorCreditoPageState extends State<SimuladorCreditoPage> {
  final _montoCtrl = TextEditingController();
  final _inicialCtrl = TextEditingController(text: '0');
  int _plazoMeses = 6;
  int _numeroCuotas = 6;

  ResumenCreditoCliente? _resumen;
  PlanPago? _plan;
  String? _error;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _inicialCtrl.dispose();
    super.dispose();
  }

  double _parse(String s) {
    final t = s.replaceAll(',', '').replaceAll(' ', '').trim();
    return double.tryParse(t) ?? 0;
  }

  void _calcular() {
    final totalVenta = _parse(_montoCtrl.text);
    final abono = _parse(_inicialCtrl.text).clamp(0.0, totalVenta);
    final capital = (totalVenta - abono).clamp(0.0, double.infinity);

    if (totalVenta <= 0) {
      setState(() {
        _error = 'Indique un monto total mayor a 0.';
        _resumen = null;
        _plan = null;
      });
      return;
    }
    if (capital <= 0) {
      setState(() {
        _error = 'El saldo a financiar debe ser mayor a RD\$ 0.00';
        _resumen = null;
        _plan = null;
      });
      return;
    }
    if (!SimuladorCreditoPage.opcionesPlazo.contains(_plazoMeses) ||
        !SimuladorCreditoPage.opcionesCuotas.contains(_numeroCuotas) ||
        _numeroCuotas > _plazoMeses) {
      setState(() {
        _error = 'Plazo/cuotas no permitidos por el módulo de créditos.';
        _resumen = null;
        _plan = null;
      });
      return;
    }

    final fechaPrimer = DateTime.now().add(const Duration(days: 30));
    const tasa = SimuladorCreditoPage.tasaMensualDefault;

    final resumen = CalculadoraCreditoService.generarResumenCliente(
      totalVenta: totalVenta,
      abonoInicial: abono,
      tasaMensual: tasa,
      numeroCuotas: _numeroCuotas,
      fechaPrimerVencimiento: fechaPrimer,
    );

    PlanPago? plan;
    if (_numeroCuotas > 1) {
      plan = CalculadoraCreditoService.generarPlanPago(
        capital: capital,
        tasaMensual: tasa,
        numeroCuotas: _numeroCuotas,
        fechaPrimerVencimiento: fechaPrimer,
      );
    }

    setState(() {
      _error = null;
      _resumen = resumen;
      _plan = plan;
    });
  }

  String _rd(double v) {
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    final chars = parts[0].split('');
    final buf = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      final fromEnd = chars.length - i;
      buf.write(chars[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return 'RD\$ ${buf.toString()}.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'SIMULAR CRÉDITO',
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: AppLayout.pantallaPadding.add(
                const EdgeInsets.only(bottom: 24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppHubHero(
                    title: 'Simulador de cuotas',
                    subtitle:
                        'Cálculo oficial del módulo de créditos. Sin cliente ni producto.',
                    icon: Icons.calculate_outlined,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      'Montos generados por CalculadoraCreditoService '
                      '(sistema francés). No es preaprobación ni contrato. '
                      'La tasa de interés no se muestra.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.85),
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          controller: _montoCtrl,
                          label: 'Monto total',
                          hint: 'Ej. 25000',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _inicialCtrl,
                          label: 'Abono inicial',
                          hint: '0',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Plazo',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final meses
                                in SimuladorCreditoPage.opcionesPlazo)
                              ChoiceChip(
                                label: Text(
                                  meses == 1 ? '1 mes' : '$meses meses',
                                ),
                                selected: _plazoMeses == meses,
                                onSelected: (_) {
                                  setState(() {
                                    _plazoMeses = meses;
                                    if (_numeroCuotas > meses) {
                                      _numeroCuotas = meses;
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Número de cuotas',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final n in SimuladorCreditoPage.opcionesCuotas
                                .where((c) => c <= _plazoMeses))
                              ChoiceChip(
                                label: Text(
                                  n == 1 ? '1 cuota' : '$n cuotas',
                                ),
                                selected: _numeroCuotas == n,
                                onSelected: (_) =>
                                    setState(() => _numeroCuotas = n),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _calcular,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text(
                              'CALCULAR',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (_resumen != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryDark,
                            AppColors.primary,
                          ],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resultado (motor oficial)',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Cuota: ${_rd(_resumen!.montoPorCuota)}',
                            style: AppTypography.h3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cuotas: ${_resumen!.numeroCuotas}\n'
                            'Interés total: ${_rd(_resumen!.montoInteres)}\n'
                            'Total a pagar: ${_rd(_resumen!.totalAPagar)}',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_plan != null && _plan!.cuotas.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Tabla de cuotas',
                      style: AppTypography.h4.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._plan!.cuotas.map(
                      (c) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              child: Text(
                                '#${c.numeroCuota}',
                                style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _rd(c.montoTotal),
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              'Cap ${_rd(c.montoCapital)} · Int ${_rd(c.montoInteres)}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
