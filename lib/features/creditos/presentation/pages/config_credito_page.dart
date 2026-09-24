import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/creditos/presentation/providers/credito_providers.dart';

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

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final tasa =
          (double.tryParse(_tasaCtrl.text.replaceAll(',', '.')) ?? 0) / 100;
      final mora =
          (double.tryParse(_moraCtrl.text.replaceAll(',', '.')) ?? 0) / 100;
      await ref.read(parametrosCreditoDaoProvider).guardar(
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración de crédito guardada'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
            return SingleChildScrollView(
              padding: AppLayout.pantallaPadding,
              child: AppLayout.centerConstrained(
                maxWidth: 720,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(
                      title: 'Parámetros',
                      subtitle: 'Valores por defecto del área de crédito',
                    ),
                    AppCard(
                      borderColor: AppColors.border,
                      child: Column(
                        children: [
                          TextField(
                            controller: _tasaCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Tasa mensual por defecto (%)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          AppLayout.vM,
                          TextField(
                            controller: _cuotasCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Cuotas por defecto',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          AppLayout.vM,
                          TextField(
                            controller: _plazoCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Plazo máximo (meses)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          AppLayout.vM,
                          TextField(
                            controller: _graciaCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Días de gracia',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          AppLayout.vM,
                          TextField(
                            controller: _moraCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Mora mensual (%)',
                              border: OutlineInputBorder(),
                              helperText: 'Política interna; se refleja en textos',
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppLayout.vL,
                    const SectionHeader(
                      title: 'Plantilla solicitud',
                      subtitle: 'Texto adicional en el PDF de solicitud',
                    ),
                    AppCard(
                      borderColor: AppColors.border,
                      child: TextField(
                        controller: _plantillaSolCtrl,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'Párrafo extra para la solicitud…',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    AppLayout.vL,
                    const SectionHeader(
                      title: 'Plantilla contrato',
                      subtitle: 'Cláusulas adicionales del contrato PDF',
                    ),
                    AppCard(
                      borderColor: AppColors.border,
                      child: TextField(
                        controller: _plantillaConCtrl,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          hintText: 'Cláusulas legales adicionales…',
                          border: OutlineInputBorder(),
                        ),
                      ),
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
            );
          },
        ),
      ),
    );
  }
}
