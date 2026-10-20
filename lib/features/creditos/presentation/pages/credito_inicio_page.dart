import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuenta_por_cobrar.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/estado_credito.dart';
import 'package:fiscogest_rd/features/creditos/presentation/pages/cuentas_cobrar_page.dart'
    show cuentasCobrarListaProvider, creditoTotalesProvider, CuentaPorCobrarBusqueda;
import 'package:fiscogest_rd/features/creditos/presentation/pages/solicitudes_credito_page.dart'
    show solicitudesCreditoProvider;
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

/// Hub de Crédito — diseño mockup + datos reales (CXC + solicitudes).
class CreditoInicioPage extends ConsumerWidget {
  const CreditoInicioPage({super.key});

  static const String routeName = 'creditos';
  static const String path = '/creditos';

  static final _fmtFecha = DateFormat('dd/MM/yyyy');
  static const _urlTransUnion =
      'https://www.transunion.com.do/ICS/pages/login.xhtml';

  Future<void> _abrirTransUnion(BuildContext context) async {
    final uri = Uri.parse(_urlTransUnion);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir TransUnion. Verifique la conexión.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir historial crediticio: $e')),
        );
      }
    }
  }

  double _cuotaAprox(CuentaPorCobrar c) {
    if (c.planPago != null) {
      final plan = c.planPago!;
      if (plan.montoPorCuota > 0) return plan.montoPorCuota;
      if (plan.cuotas.isNotEmpty) {
        final pend = plan.cuotas.where((q) => !q.pagada).toList();
        if (pend.isNotEmpty) return pend.first.montoTotal;
        return plan.cuotas.first.montoTotal;
      }
    }
    final n = c.numeroCuotas <= 0 ? 1 : c.numeroCuotas;
    return c.totalAPagar / n;
  }


  double _usoCredito(CuentaPorCobrar c) {
    final total = c.totalAPagar;
    if (total <= 0) return 0;
    return (c.saldoPendiente / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);
    final totalesAsync = ref.watch(creditoTotalesProvider);
    final cuentasAsync = ref.watch(cuentasCobrarListaProvider);
    final solsAsync = ref.watch(solicitudesCreditoProvider);

    final porCobrarStr = totalesAsync.when(
      data: (t) => formatRd(t.porCobrar),
      loading: () => '…',
      error: (_, __) => '—',
    );
    final vencidoStr = totalesAsync.when(
      data: (t) => formatRd(t.vencido),
      loading: () => '…',
      error: (_, __) => '—',
    );
    final alDiaStr = totalesAsync.when(
      data: (t) {
        final alDia = t.porCobrar - t.vencido;
        return formatRd(alDia < 0 ? 0.0 : alDia);
      },
      loading: () => '…',
      error: (_, __) => '—',
    );
    final clientesStr = totalesAsync.when(
      data: (t) => '${t.clientes}',
      loading: () => '…',
      error: (_, __) => '—',
    );

    return AppScaffold(
      title: 'CRÉDITO',
      showAppBar: !desktop,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              mobile ? 16 : 24,
              mobile ? 12 : 20,
              mobile ? 16 : 24,
              32,
            ),
            child: AppLayout.centerConstrained(
              maxWidth: desktop ? 1180 : 720,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (desktop)
                    const EnterprisePageHeader(
                      title: 'Gestión de Crédito y Cuentas por Cobrar',
                    ),

                  // ── KPIs (estilo mockup: vencido en rosa claro) ──
                  if (desktop)
                    Row(
                      children: [
                        Expanded(
                          child: _KpiCard(
                            icon: Icons.account_balance_wallet_outlined,
                            value: porCobrarStr,
                            label: 'POR COBRAR',
                            solid: true,
                            bg: const Color(0xFF059669),
                            fg: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KpiCard(
                            icon: Icons.warning_amber_rounded,
                            value: vencidoStr,
                            label: 'VENCIDO',
                            solid: false,
                            bg: const Color(0xFFFFE4E6),
                            fg: const Color(0xFFBE123C),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KpiCard(
                            icon: Icons.verified_outlined,
                            value: alDiaStr,
                            label: 'AL DÍA',
                            solid: true,
                            bg: const Color(0xFF2563EB),
                            fg: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KpiCard(
                            icon: Icons.assignment_outlined,
                            value: clientesStr,
                            label: 'CLIENTES EN CRÉDITO',
                            solid: true,
                            bg: const Color(0xFF7C3AED),
                            fg: Colors.white,
                          ),
                        ),
                      ],
                    )
                  else
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.15,
                      children: [
                        _KpiCard(
                          icon: Icons.account_balance_wallet_outlined,
                          value: porCobrarStr,
                          label: 'POR COBRAR',
                          solid: true,
                          bg: const Color(0xFF059669),
                          fg: Colors.white,
                        ),
                        _KpiCard(
                          icon: Icons.warning_amber_rounded,
                          value: vencidoStr,
                          label: 'VENCIDO',
                          solid: false,
                          bg: const Color(0xFFFFE4E6),
                          fg: const Color(0xFFBE123C),
                        ),
                        _KpiCard(
                          icon: Icons.verified_outlined,
                          value: alDiaStr,
                          label: 'AL DÍA',
                          solid: true,
                          bg: const Color(0xFF2563EB),
                          fg: Colors.white,
                        ),
                        _KpiCard(
                          icon: Icons.assignment_outlined,
                          value: clientesStr,
                          label: 'CLIENTES',
                          solid: true,
                          bg: const Color(0xFF7C3AED),
                          fg: Colors.white,
                        ),
                      ],
                    ),
                  const SizedBox(height: 22),

                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _CxcPanel(
                            async: cuentasAsync,
                            fmtFecha: _fmtFecha,
                            cuotaOf: _cuotaAprox,
                            usoOf: _usoCredito,
                            onVerTodos: () =>
                                context.push('/creditos/cuentas'),
                            onTapCuenta: (id) {
                              if (id != null) {
                                context.push('/creditos/cuentas/$id');
                              } else {
                                context.push('/creditos/cuentas');
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              _SolicitudesPanel(
                                async: solsAsync,
                                onVerTodas: () =>
                                    context.push('/creditos/solicitudes'),
                                onTapSol: (id) => context.push(
                                  '/creditos/solicitudes/$id',
                                ),
                              ),
                              const SizedBox(height: 14),
                              _AccionesRapidas(
                                onNuevo: () =>
                                    context.push('/creditos/solicitudes'),
                                onCobro: () =>
                                    context.push('/creditos/cuentas'),
                                onRiesgo: () => _abrirTransUnion(context),
                                onVerSolicitudes: () =>
                                    context.push('/creditos/solicitudes'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _CxcPanel(
                      async: cuentasAsync,
                      fmtFecha: _fmtFecha,
                      cuotaOf: _cuotaAprox,
                      usoOf: _usoCredito,
                      onVerTodos: () => context.push('/creditos/cuentas'),
                      onTapCuenta: (id) {
                        if (id != null) {
                          context.push('/creditos/cuentas/$id');
                        } else {
                          context.push('/creditos/cuentas');
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    _SolicitudesPanel(
                      async: solsAsync,
                      onVerTodas: () =>
                          context.push('/creditos/solicitudes'),
                      onTapSol: (id) =>
                          context.push('/creditos/solicitudes/$id'),
                    ),
                    const SizedBox(height: 14),
                    _AccionesRapidas(
                      onNuevo: () => context.push('/creditos/solicitudes'),
                      onCobro: () => context.push('/creditos/cuentas'),
                      onRiesgo: () => _abrirTransUnion(context),
                      onVerSolicitudes: () =>
                          context.push('/creditos/solicitudes'),
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

// ── KPI ──────────────────────────────────────
class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.bg,
    required this.fg,
    required this.solid,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color bg;
  final Color fg;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: narrow ? 10 : 16,
        vertical: narrow ? 10 : 16,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(narrow ? 12 : 16),
        border: solid ? null : Border.all(color: fg.withValues(alpha: 0.2)),
        boxShadow: solid
            ? [
                BoxShadow(
                  color: bg.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: narrow ? 32 : 40,
            height: narrow ? 32 : 40,
            decoration: BoxDecoration(
              color: solid
                  ? Colors.white.withValues(alpha: 0.2)
                  : fg.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(narrow ? 8 : 12),
            ),
            child: Icon(
              icon,
              color: solid ? Colors.white : fg,
              size: narrow ? 18 : 22,
            ),
          ),
          SizedBox(width: narrow ? 8 : 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: narrow ? 14 : 18,
                    fontWeight: FontWeight.w800,
                    color: solid ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: narrow ? 9 : 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    height: 1.1,
                    color: solid
                        ? Colors.white.withValues(alpha: 0.85)
                        : fg,
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

// ── Panel CXC ────────────────────────────────
class _CxcPanel extends StatelessWidget {
  const _CxcPanel({
    required this.async,
    required this.fmtFecha,
    required this.cuotaOf,
    required this.usoOf,
    required this.onVerTodos,
    required this.onTapCuenta,
  });

  final AsyncValue<List<CuentaPorCobrarBusqueda>> async;
  final DateFormat fmtFecha;
  final double Function(CuentaPorCobrar) cuotaOf;
  final double Function(CuentaPorCobrar) usoOf;
  final VoidCallback onVerTodos;
  final void Function(int? id) onTapCuenta;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 700;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'Próximos vencimientos',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          if (!mobile)
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: const Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text('Cliente',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B))),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text('RNC',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B))),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text('Vence',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B))),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Text('Cuota',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B))),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Text('Límite / Uso',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B))),
                  ),
                ],
              ),
            ),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('$e',
                  style:
                      const TextStyle(color: Color(0xFFBE123C), fontSize: 12)),
            ),
            data: (lista) {
              final activas = lista
                  .where((x) => x.cuenta.estado != EstadoCredito.pagado)
                  .toList()
                ..sort((a, b) => a.cuenta.fechaVencimiento
                    .compareTo(b.cuenta.fechaVencimiento));
              final top = activas.take(5).toList();
              if (top.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No hay cuentas por cobrar activas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                );
              }
              if (mobile) {
                return Column(
                  children: [
                    for (final item in top)
                      _CxcCardMobile(
                        nombre: item.cuenta.clienteNombre ??
                            'Cliente #${item.cuenta.clienteId}',
                        rnc: item.documentoCliente.isEmpty
                            ? '—'
                            : item.documentoCliente,
                        fecha: fmtFecha.format(item.cuenta.fechaVencimiento),
                        cuota: formatRd(cuotaOf(item.cuenta)),
                        saldo: formatRd(item.cuenta.saldoPendiente),
                        uso: usoOf(item.cuenta),
                        onTap: () => onTapCuenta(item.cuenta.id),
                      ),
                  ],
                );
              }
              return Column(
                children: [
                  for (final item in top)
                    _CxcRow(
                      nombre: item.cuenta.clienteNombre ??
                          'Cliente #${item.cuenta.clienteId}',
                      rnc: item.documentoCliente.isEmpty
                          ? '—'
                          : item.documentoCliente,
                      fecha: fmtFecha.format(item.cuenta.fechaVencimiento),
                      cuota: formatRd(cuotaOf(item.cuenta)),
                      saldo: formatRd(item.cuenta.saldoPendiente),
                      uso: usoOf(item.cuenta),
                      onTap: () => onTapCuenta(item.cuenta.id),
                    ),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onVerTodos,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Ver todos los vencimientos →',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CxcCardMobile extends StatelessWidget {
  const _CxcCardMobile({
    required this.nombre,
    required this.rnc,
    required this.fecha,
    required this.cuota,
    required this.saldo,
    required this.uso,
    required this.onTap,
  });

  final String nombre;
  final String rnc;
  final String fecha;
  final String cuota;
  final String saldo;
  final double uso;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = (uso * 100).round();
    final barColor =
        uso >= 0.85 ? const Color(0xFFF59E0B) : const Color(0xFF2563EB);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 18, color: Color(0xFF94A3B8)),
                ],
              ),
              if (rnc != '—') ...[
                const SizedBox(height: 2),
                Text(
                  'RNC: $rnc',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Vence $fecha',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  Text(
                    'Cuota $cuota',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: uso.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        color: barColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$saldo · $pct%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CxcRow extends StatelessWidget {
  const _CxcRow({
    required this.nombre,
    required this.rnc,
    required this.fecha,
    required this.cuota,
    required this.saldo,
    required this.uso,
    required this.onTap,
  });

  final String nombre;
  final String rnc;
  final String fecha;
  final String cuota;
  final String saldo;
  final double uso;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = (uso * 100).round();
    final barColor =
        uso >= 0.85 ? const Color(0xFFF59E0B) : const Color(0xFF2563EB);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        size: 17,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  rnc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  fecha,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  cuota,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$saldo  ·  $pct%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: uso.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        color: barColor,
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

// ── Solicitudes ──────────────────────────────
class _SolicitudesPanel extends StatelessWidget {
  const _SolicitudesPanel({
    required this.async,
    required this.onVerTodas,
    required this.onTapSol,
  });

  final AsyncValue<List<Venta>> async;
  final VoidCallback onVerTodas;
  final void Function(int id) onTapSol;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Solicitudes de Crédito Recientes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              TextButton(
                onPressed: onVerTodas,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Ver todas',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Text('$e',
                style: const TextStyle(color: Color(0xFFBE123C), fontSize: 12)),
            data: (lista) {
              final top = lista.take(4).toList();
              if (top.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No hay solicitudes en análisis.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                  ),
                );
              }
              return Column(
                children: [
                  for (final v in top) ...[
                    _SolItem(
                      nombre: (v.nombreCliente?.trim().isNotEmpty == true)
                          ? v.nombreCliente!
                          : 'Cliente #${v.clienteId}',
                      detalle:
                          'Monto: ${formatRd(v.montoTotal)} · ${v.numeroCotizacion}',
                      chip: 'Pendiente',
                      chipColor: const Color(0xFFB45309),
                      chipBg: const Color(0xFFFEF3C7),
                      onTap: () {
                        if (v.id != null) onTapSol(v.id!);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SolItem extends StatelessWidget {
  const _SolItem({
    required this.nombre,
    required this.detalle,
    required this.chip,
    required this.chipColor,
    required this.chipBg,
    this.onTap,
  });

  final String nombre;
  final String detalle;
  final String chip;
  final Color chipColor;
  final Color chipBg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.business_outlined,
                    size: 16, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      detalle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  chip,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: chipColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Acciones rápidas ─────────────────────────
class _AccionesRapidas extends StatelessWidget {
  const _AccionesRapidas({
    required this.onNuevo,
    required this.onCobro,
    required this.onRiesgo,
    required this.onVerSolicitudes,
  });

  final VoidCallback onNuevo;
  final VoidCallback onCobro;
  final VoidCallback onRiesgo;
  final VoidCallback onVerSolicitudes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Acciones Rápidas',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AccionTile(
                  icon: Icons.note_add_outlined,
                  label: 'Nuevo\nCrédito',
                  bg: const Color(0xFFF1F5F9),
                  fg: const Color(0xFF334155),
                  onTap: onNuevo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AccionTile(
                  icon: Icons.payments_outlined,
                  label: 'Registrar\nCobro',
                  bg: const Color(0xFFEFF6FF),
                  fg: const Color(0xFF2563EB),
                  onTap: onCobro,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AccionTile(
                  icon: Icons.policy_outlined,
                  label: 'Analizar\nRiesgo',
                  bg: const Color(0xFFF5F3FF),
                  fg: const Color(0xFF7C3AED),
                  onTap: onRiesgo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _AccionTile extends StatelessWidget {
  const _AccionTile({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: fg, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
