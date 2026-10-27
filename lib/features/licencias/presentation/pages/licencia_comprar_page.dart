
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/features/licencias/domain/planes_precios.dart';
import 'package:fiscogest_rd/features/licencias/domain/paypal_config.dart';
import 'package:fiscogest_rd/features/licencias/data/paypal_service.dart';
import 'package:fiscogest_rd/features/licencias/presentation/pages/paypal_checkout_page.dart';
import 'package:fiscogest_rd/features/licencias/presentation/providers/licencia_providers.dart';

/// Compra: solo PayPal en USD. PC sin AppBar; móvil con AppBar + scroll.
class LicenciaComprarPage extends ConsumerStatefulWidget {
  const LicenciaComprarPage({super.key});

  static const routeName = 'licencia-comprar';
  static const path = '/licencia/comprar';

  @override
  ConsumerState<LicenciaComprarPage> createState() =>
      _LicenciaComprarPageState();
}

class _LicenciaComprarPageState extends ConsumerState<LicenciaComprarPage> {
  bool _cargando = false;
  String? _planEnProceso;

  static const _planes = ['gratis', 'basico', 'simplificado', 'pro'];
  static const _teal = Color(0xFF00A896);
  static const _ink = Color(0xFF0D1E34);

  Future<void> _pagarPayPal(String plan) async {
    if (plan == 'gratis') {
      _snack(
        'El plan Gratis no requiere pago. '
        'Se aplica al terminar la prueba o desde Mi licencia.',
      );
      return;
    }
    final montoUsd = precioMensualUsd(plan);
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
    setState(() {
      _cargando = true;
      _planEnProceso = plan;
    });
    try {
      final svc = ref.read(licenciaServiceProvider);

      // Generamos la referencia SOLO en memoria.
      // El pedido NO se crea todavía (evita tokens basura).
      final refCode = await svc.generarReferenciaUnica();

      final paypal = PaypalService();
      final order = await paypal.createOrder(
        amountUsd: montoUsd,
        reference: refCode,
        description: 'FiscoGest ${nombrePlanUi(plan)} mensual',
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

      // Solo aquí, después de confirmación de PayPal, se crea el pedido y se emite la licencia
      await svc.crearPedidoTrasPagoExitoso(
        referencia: refCode,
        plan: plan,
        vigenciaTipo: 'mensual',
        medioPreferido: 'paypal',
      );

      ref.invalidate(licenciaActualProvider);
      if (!mounted) return;
      _snack('¡Pago recibido! Tu plan ${nombrePlanUi(plan)} ya está activo.');
      await Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
          _planEnProceso = null;
        });
      }
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  String _planActualId() {
    final async = ref.watch(licenciaActualProvider);
    return async.maybeWhen(
      data: (info) {
        final p = (info?.plan ?? 'gratis').toLowerCase().trim();
        if (p == 'profesional') return 'pro';
        return p;
      },
      orElse: () => 'gratis',
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final planActual = _planActualId();
    final padH = mobile ? 16.0 : 28.0;

    return AppScaffold(
      title: 'Planes y pago',
      showAppBar: mobile,
      showBackButton: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!mobile)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 10, 20, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back, color: _teal),
                      tooltip: 'Volver',
                    ),
                    const Text(
                      'Planes y pago',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),
            if (!mobile)
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = mobile ? 560.0 : 1100.0;
                  final contentW = constraints.maxWidth > maxW
                      ? maxW
                      : constraints.maxWidth;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxW),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          padH,
                          mobile ? 16 : 28,
                          padH,
                          32,
                        ),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: _teal,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Elige tu plan: Solo PayPal en USD. Tu plan queda activo al instante.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          _PricingGrid(
                            planes: _planes,
                            planActual: planActual,
                            cargando: _cargando,
                            planEnProceso: _planEnProceso,
                            onSelect: _pagarPayPal,
                            maxWidth: contentW - padH * 2,
                          ),
                          const SizedBox(height: 20),
                          const Text(
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
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PricingGrid extends StatelessWidget {
  const _PricingGrid({
    required this.planes,
    required this.planActual,
    required this.cargando,
    required this.planEnProceso,
    required this.onSelect,
    required this.maxWidth,
  });

  final List<String> planes;
  final String planActual;
  final bool cargando;
  final String? planEnProceso;
  final void Function(String plan) onSelect;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    int cols;
    if (maxWidth < 560) {
      cols = 1;
    } else if (maxWidth < 900) {
      cols = 2;
    } else {
      cols = planes.length >= 4 ? 4 : 3;
    }
    const gap = 20.0;
    final cardW = ((maxWidth - gap * (cols - 1)) / cols).clamp(240.0, 340.0);

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      alignment: WrapAlignment.center,
      children: [
        for (final p in planes)
          SizedBox(
            width: cardW,
            child: _PriceCard(
              plan: p,
              esActivo: _esMismoPlan(p, planActual),
              cargando: cargando && planEnProceso == p,
              disabled: cargando,
              onAction: () => onSelect(p),
            ),
          ),
      ],
    );
  }

  bool _esMismoPlan(String a, String b) {
    final x = a.toLowerCase();
    final y = b.toLowerCase();
    if (x == y) return true;
    if ((x == 'pro' || x == 'profesional') &&
        (y == 'pro' || y == 'profesional')) {
      return true;
    }
    return false;
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.plan,
    required this.esActivo,
    required this.cargando,
    required this.disabled,
    required this.onAction,
  });

  final String plan;
  final bool esActivo;
  final bool cargando;
  final bool disabled;
  final VoidCallback onAction;

  static const _teal = Color(0xFF00A896);
  static const _ink = Color(0xFF0D1E34);

  @override
  Widget build(BuildContext context) {
    final precio = precioMensualUsd(plan) ?? 0;
    final features = _features(plan);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esActivo ? _teal : const Color(0xFFE2E8F0),
          width: esActivo ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: esActivo
                ? _teal.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: esActivo ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (esActivo)
            Align(
              alignment: Alignment.centerRight,
              child: Transform.translate(
                offset: const Offset(0, -14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _teal,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PLAN ACTIVO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ),
          Text(
            nombrePlanUi(plan),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'US\$ ${precio.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _teal,
                  ),
                ),
                const TextSpan(
                  text: ' / mes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final f in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    f.ok ? Icons.check_rounded : Icons.close_rounded,
                    size: 18,
                    color: f.ok
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f.text,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.3,
                        color: f.ok
                            ? const Color(0xFF475569)
                            : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: esActivo
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Tu plan actual',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  )
                : FilledButton(
                    onPressed: disabled ? null : onAction,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          plan == 'gratis' ? Colors.white : _teal,
                      foregroundColor: plan == 'gratis'
                          ? const Color(0xFF475569)
                          : Colors.white,
                      side: plan == 'gratis'
                          ? const BorderSide(color: Color(0xFFCBD5E1))
                          : BorderSide.none,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: cargando
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: plan == 'gratis'
                                  ? _teal
                                  : Colors.white,
                            ),
                          )
                        : Text(
                            plan == 'pro'
                                ? 'Mejorar a Pro'
                                : 'Cambiar a este plan',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  List<_Feat> _features(String plan) {
    switch (plan.toLowerCase()) {
      case 'gratis':
        return const [
          _Feat(true, 'Ventas y caja'),
          _Feat(true, 'Catálogo limitado (productos / clientes)'),
          _Feat(true, 'Fiao básico'),
          _Feat(true, '1 equipo'),
          _Feat(false, 'Sin reportes ni módulo fiscal'),
        ];
      case 'basico':
        return const [
          _Feat(true, 'Hasta 50 facturas al mes'),
          _Feat(true, 'Ventas, compras, inventario y caja'),
          _Feat(true, 'Productos y clientes sin tope práctico'),
          _Feat(true, 'Reportes para decidir con datos'),
          _Feat(true, 'Fiao · 1 equipo'),
        ];
      case 'simplificado':
        return const [
          _Feat(true, 'Todo lo de Básico'),
          _Feat(true, 'Hasta 150 facturas al mes'),
          _Feat(true, 'Más holgura de fiao'),
          _Feat(true, 'Mismos reportes e inventario'),
          _Feat(false, 'Sin almacenes ni e-CF'),
        ];
      case 'pro':
        return const [
          _Feat(true, 'Ventas sin tope práctico + ITBIS'),
          _Feat(true, 'RNC de la empresa y secuencias NCF'),
          _Feat(true, 'Facturación electrónica e-CF (DGII)'),
          _Feat(true, 'Almacenes, transferencias y multiequipo'),
          _Feat(true, 'Crédito formal y usuarios por equipo'),
        ];
      default:
        return const [];
    }
  }
}

class _Feat {
  const _Feat(this.ok, this.text);
  final bool ok;
  final String text;
}
