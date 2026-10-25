import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/features/licencias/domain/planes_precios.dart';
import 'package:fiscogest_rd/features/licencias/domain/paypal_config.dart';
import 'package:fiscogest_rd/features/licencias/data/paypal_service.dart';
import 'package:fiscogest_rd/features/licencias/presentation/pages/paypal_checkout_page.dart';
import 'package:fiscogest_rd/features/licencias/presentation/providers/licencia_providers.dart';

/// Compra móvil: solo PayPal en USD, activación automática.
class LicenciaComprarPage extends ConsumerStatefulWidget {
  const LicenciaComprarPage({super.key});

  static const routeName = 'licencia-comprar';
  static const path = '/licencia/comprar';

  @override
  ConsumerState<LicenciaComprarPage> createState() =>
      _LicenciaComprarPageState();
}

class _LicenciaComprarPageState extends ConsumerState<LicenciaComprarPage> {
  String _plan = 'basico';
  bool _cargando = false;

  static const _planes = ['basico', 'simplificado', 'pro'];

  double get _precioUsd => precioMensualUsd(_plan) ?? 0;

  Future<void> _pagarPayPal() async {
    final montoUsd = precioMensualUsd(_plan);
    if (montoUsd == null) {
      _snack('Este plan no tiene precio de suscripción.');
      return;
    }
    if (!PaypalConfig.configurado) {
      _snack(
        'El pago en línea no está disponible en esta instalación. '
        'Reinstala la app desde la última versión publicada o contacta soporte.',
      );
      return;
    }

    setState(() => _cargando = true);
    try {
      final svc = ref.read(licenciaServiceProvider);
      final refCode = await svc.crearPedido(
        plan: _plan,
        vigenciaTipo: 'mensual',
        medioPreferido: 'paypal',
      );

      final paypal = PaypalService();
      final order = await paypal.createOrder(
        amountUsd: montoUsd,
        reference: refCode,
        description: 'FiscoGest ${nombrePlanUi(_plan)} mensual',
      );

      if (!mounted) return;
      final result = await Navigator.of(context).push<PaypalCheckoutResult>(
        MaterialPageRoute(
          builder: (_) => PaypalCheckoutPage(
            approveUrl: order.approveUrl,
            orderId: order.orderId,
          ),
        ),
      );

      if (!mounted) return;
      if (result == null || result.cancelled) {
        _snack('Pago cancelado.');
        return;
      }
      if (!result.success) {
        _snack(result.error ?? 'No se completó el pago.');
        return;
      }

      await svc.marcarPagadoYEmitirLicencia(refCode);
      ref.invalidate(licenciaActualProvider);

      if (!mounted) return;
      _snack('¡Pago recibido! Tu plan ${nombrePlanUi(_plan)} ya está activo.');
      await Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final pad = w < 700 ? 16.0 : 24.0;

    return AppScaffold(
      title: 'Planes y pago',
      body: ListView(
        padding: EdgeInsets.fromLTRB(pad, 12, pad, 32),
        children: [
          _Hero(),
          const SizedBox(height: 20),
          for (final p in _planes) ...[
            _PlanCard(
              plan: p,
              selected: _plan == p,
              onTap: () => setState(() => _plan = p),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'US\$ ${_precioUsd.toStringAsFixed(2)} / mes',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cobro en USD · activación automática al confirmar PayPal',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _cargando ? null : _pagarPayPal,
              icon: _cargando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.payment),
              label: Text(
                _cargando ? 'Procesando…' : 'Pagar con PayPal',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tras el pago, la licencia se activa sola. No hace falta enviar comprobantes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.workspace_premium, color: Colors.white, size: 32),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Elige tu plan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Solo PayPal en USD. Tu plan queda activo al instante.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final String plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final precio = precioMensualUsd(plan) ?? 0;
    final beneficios = beneficiosPlanUi(plan);
    final destacado = plan == 'pro';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF0F766E)
                  : const Color(0xFFE2E8F0),
              width: selected ? 2 : 1,
            ),
            color: selected
                ? const Color(0xFF0F766E).withValues(alpha: 0.04)
                : Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          nombrePlanUi(plan),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? const Color(0xFF0F766E)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        if (destacado) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F766E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Recomendado',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected
                        ? const Color(0xFF0F766E)
                        : const Color(0xFF94A3B8),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'US\$ ${precio.toStringAsFixed(2)} / mes',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              for (final b in beneficios)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Color(0xFF0F766E),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          b,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
