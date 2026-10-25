import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/licencias/domain/medios_cobro.dart';
import 'package:fiscogest_rd/features/licencias/domain/planes_precios.dart';
import 'package:fiscogest_rd/features/licencias/domain/paypal_config.dart';
import 'package:fiscogest_rd/features/licencias/data/paypal_service.dart';
import 'package:fiscogest_rd/features/licencias/presentation/pages/paypal_checkout_page.dart';
import 'package:fiscogest_rd/features/licencias/presentation/providers/licencia_providers.dart';

class LicenciaComprarPage extends ConsumerStatefulWidget {
  const LicenciaComprarPage({super.key});

  static const routeName = 'licencia-comprar';
  static const path = '/licencia/comprar';

  @override
  ConsumerState<LicenciaComprarPage> createState() => _LicenciaComprarPageState();
}

class _LicenciaComprarPageState extends ConsumerState<LicenciaComprarPage> {
  String _plan = 'basico';
  String _vigencia = 'mensual';
  String? _referencia;
  double? _monto;
  bool _cargando = false;
  String? _medioId = 'toke';

  double? get _precio => precioPlanVigencia(_plan, _vigencia);

  Future<void> _generarPedido() async {
    final montoUsd = precioMensualUsd(_plan);
    if (montoUsd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este plan no tiene precio de suscripción móvil.'),
        ),
      );
      return;
    }
    if (!PaypalConfig.configurado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PayPal no configurado. Ejecuta con '
            '--dart-define=PAYPAL_CLIENT_ID=... --dart-define=PAYPAL_SECRET=...',
          ),
        ),
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
        description: 'FiscoGest $_plan mensual',
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago cancelado.')),
        );
        return;
      }
      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'No se completó el pago.')),
        );
        return;
      }

      // Pago OK → emitir licencia (sin transferencia manual)
      await svc.marcarPagadoYEmitirLicencia(refCode);
      ref.invalidate(licenciaActualProvider);
      if (!mounted) return;
      setState(() {
        _referencia = refCode;
        _monto = montoUsd;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Pago recibido! Tu licencia está activa.'),
        ),
      );
      // Volver a estado de licencia
      if (mounted) await Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }


  Future<void> _yaPague() async {
    if (_referencia == null) return;
    await ref.read(licenciaServiceProvider).marcarPagoReportado(_referencia!);
    if (!mounted) return;
    FiscoGestNotifications.show(
      const SnackBar(
        content: Text(
          'Pago reportado. Cuando confirmemos el depósito, tu licencia quedará activa.',
        ),
      ),
    );
  }

  void _copiar(String texto) {
    Clipboard.setData(ClipboardData(text: texto));
    FiscoGestNotifications.show(const SnackBar(content: Text('Copiado')));
  }

  @override
  @override
  Widget build(BuildContext context) {
    final esMovil = MediaQuery.sizeOf(context).width < 700;

    return AppScaffold(
      title: 'Comprar licencia',
      body: ListView(
        padding: EdgeInsets.fromLTRB(esMovil ? 16 : 24, 16, esMovil ? 16 : 24, 32),
        children: [
          _BannerPago(esMovil: esMovil),
          const SizedBox(height: 20),

          const _SectionLabel('Plan'),
          const SizedBox(height: 8),
          Text(
            'Sin fiscal (ambulantes)',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PlanChip(
                label: 'Simplificado · desde RD\$300',
                selected: _plan == 'simplificado',
                onTap: () => setState(() {
                  _plan = 'simplificado';
                  if (!vigenciasDisponiblesParaPlan('simplificado')
                      .contains(_vigencia)) {
                    _vigencia = 'mensual';
                  }
                  _referencia = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Modo normal — US\$15.99/mes',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in ['basico'])  // profesional/empresa → contacto FiscoGest
                _PlanChip(
                  label: p[0].toUpperCase() + p.substring(1),
                  selected: _plan == p,
                  onTap: () => setState(() {
                    _plan = p;
                    if (!vigenciasDisponiblesParaPlan(p).contains(_vigencia)) {
                      _vigencia = 'mensual';
                    }
                    _referencia = null;
                  }),
                ),
            ],
          ),
          if (descripcionPlanCorta(_plan).isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              descripcionPlanCorta(_plan),
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],

          const SizedBox(height: 20),
          const _SectionLabel('Periodo'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in vigenciasDisponiblesParaPlan(_plan))
                _PlanChip(
                  label: v,
                  selected: _vigencia == v,
                  onTap: () => setState(() {
                    _vigencia = v;
                    _referencia = null;
                  }),
                ),
            ],
          ),

          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monto: RD\$ ${(_precio ?? 0).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  esPlanSimplificado(_plan)
                      ? 'Sin impuestos · 1 dispositivo · fiao hasta 50 cuentas'
                      : 'Máx. cajas: ${kMaxCajasPorPlan[_plan] ?? 1}'
                          ' · Instalaciones: ${maxInstalacionesPermitidas(_plan)}'
                          ' (incluye 1 celular gratis)'
                          '${planIncluyeEcf(_plan) ? ' · e-CF' : ''}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          if (_referencia == null)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _cargando ? null : _generarPedido,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(_cargando ? 'Procesando…' : 'Pagar con PayPal'),
              ),
            )
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tu referencia',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _referencia!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _copiar(_referencia!),
                        icon: const Icon(Icons.copy, color: Colors.white),
                      ),
                    ],
                  ),
                  Text(
                    'Monto exacto: RD\$ ${(_monto ?? 0).toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Incluye esta referencia en el concepto. Vence en 7 días si no se confirma.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _SectionLabel('Medios de pago'),
            const SizedBox(height: 10),
            ...kMediosCobroMartTech.map((m) {
              final sel = _medioId == m.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() => _medioId = m.id),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF0F766E)
                              : Colors.black.withValues(alpha: 0.06),
                          width: sel ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.nombre,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: sel
                                        ? const Color(0xFF0F766E)
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${m.etiquetaDato}: ${m.dato}\n'
                                  'Titular: ${m.titular}\n'
                                  '${m.instruccionCorta}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_outlined),
                            onPressed: () => _copiar(m.dato),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _yaPague,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirmar suscripción'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BannerPago extends StatelessWidget {
  const _BannerPago({required this.esMovil});
  final bool esMovil;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(esMovil ? 18 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.payments_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pago de licencia',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Toke o transferencia. Genera FG-XXXXX e inclúyelo en el concepto.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.labelLarge);
  }
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? const Color(0xFF0F766E) : const Color(0xFF334155),
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFF0F766E).withValues(alpha: 0.12),
      checkmarkColor: const Color(0xFF0F766E),
      side: BorderSide(
        color: selected
            ? const Color(0xFF0F766E)
            : Colors.black.withValues(alpha: 0.08),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
    );
  }
}
