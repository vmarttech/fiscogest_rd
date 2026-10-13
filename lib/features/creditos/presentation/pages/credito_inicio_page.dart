import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/creditos/presentation/pages/cuentas_cobrar_page.dart'
    show creditoTotalesProvider;

/// Hub de Crédito — layout SaaS premium (PC) alineado al mockup.
class CreditoInicioPage extends ConsumerWidget {
  const CreditoInicioPage({super.key});

  static const String routeName = 'creditos';
  static const String path = '/creditos';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);

    final totalesAsync = ref.watch(creditoTotalesProvider);
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
              maxWidth: desktop ? 1100 : 720,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Banner compacto ──
                  _BannerCredito(mobile: mobile),
                  const SizedBox(height: 18),

                  // ── KPIs ──
                  if (desktop)
                    Row(
                      children: [
                        Expanded(
                          child: _KpiPill(
                            icon: Icons.account_balance_wallet_outlined,
                            value: porCobrarStr,
                            label: 'POR COBRAR',
                            bg: const Color(0xFFECFDF5),
                            fg: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _KpiPill(
                            icon: Icons.warning_amber_rounded,
                            value: vencidoStr,
                            label: 'VENCIDO',
                            bg: const Color(0xFFFEF2F2),
                            fg: AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _KpiPill(
                            icon: Icons.verified_outlined,
                            value: alDiaStr,
                            label: 'AL DÍA',
                            bg: const Color(0xFFEFF6FF),
                            fg: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _KpiPill(
                            icon: Icons.assignment_outlined,
                            value: clientesStr,
                            label: 'CLIENTES',
                            bg: const Color(0xFFF5F3FF),
                            fg: const Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    )
                  else
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.55,
                      children: [
                        _KpiPill(
                          icon: Icons.account_balance_wallet_outlined,
                          value: porCobrarStr,
                          label: 'POR COBRAR',
                          bg: const Color(0xFFECFDF5),
                          fg: AppColors.success,
                        ),
                        _KpiPill(
                          icon: Icons.warning_amber_rounded,
                          value: vencidoStr,
                          label: 'VENCIDO',
                          bg: const Color(0xFFFEF2F2),
                          fg: AppColors.error,
                        ),
                        _KpiPill(
                          icon: Icons.verified_outlined,
                          value: alDiaStr,
                          label: 'AL DÍA',
                          bg: const Color(0xFFEFF6FF),
                          fg: AppColors.info,
                        ),
                        _KpiPill(
                          icon: Icons.assignment_outlined,
                          value: clientesStr,
                          label: 'CLIENTES',
                          bg: const Color(0xFFF5F3FF),
                          fg: const Color(0xFF7C3AED),
                        ),
                      ],
                    ),

                  const SizedBox(height: 22),

                  // ── Operaciones ──
                  Text(
                    'Operaciones',
                    style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _OpCard(
                            icon: Icons.assignment_outlined,
                            title: 'Solicitudes',
                            subtitle: 'Pendientes, historial y aprobación',
                            color: AppColors.primary,
                            onTap: () =>
                                context.push('/creditos/solicitudes'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OpCard(
                            icon: Icons.description_outlined,
                            title: 'Cuentas por cobrar',
                            subtitle: 'Saldos, cuotas y cobros',
                            color: const Color(0xFF6366F1),
                            onTap: () => context.push('/creditos/cuentas'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Padding(
                          padding: const EdgeInsets.only(top: 18),
                          child: TextButton(
                            onPressed: () => context.push('/creditos/config'),
                            child: Text(
                              'Configuración · Plazos, tasas y políticas →',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _OpCard(
                      icon: Icons.assignment_outlined,
                      title: 'Solicitudes',
                      subtitle: 'Pendientes, historial y aprobación',
                      color: AppColors.primary,
                      onTap: () => context.push('/creditos/solicitudes'),
                    ),
                    const SizedBox(height: 10),
                    _OpCard(
                      icon: Icons.description_outlined,
                      title: 'Cuentas por cobrar',
                      subtitle: 'Saldos, cuotas y cobros',
                      color: const Color(0xFF6366F1),
                      onTap: () => context.push('/creditos/cuentas'),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => context.push('/creditos/config'),
                        child: Text(
                          'Configuración · Plazos, tasas y políticas →',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Listas inferiores ──
                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ListaPanel(
                            title: 'Próximos vencimientos',
                            footerLabel: 'Ver todos los vencimientos →',
                            onFooter: () => context.push('/creditos/cuentas'),
                            children: const [
                              _ListaItem(
                                nombre: 'Cliente Corporativo ABC, S.A.',
                                detalle: 'Vence próximamente',
                                valor: '—',
                                valorColor: AppColors.error,
                              ),
                              _ListaItem(
                                nombre: 'Distribuidora del Caribe',
                                detalle: 'Vence próximamente',
                                valor: '—',
                                valorColor: AppColors.error,
                              ),
                              _ListaItem(
                                nombre: 'Servicios Técnicos Global, SRL',
                                detalle: 'Vence próximamente',
                                valor: '—',
                                valorColor: AppColors.error,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _ListaPanel(
                            title: 'Solicitudes recientes',
                            footerLabel: 'Ver todas las solicitudes →',
                            onFooter: () =>
                                context.push('/creditos/solicitudes'),
                            children: const [
                              _ListaItem(
                                nombre: 'Inversiones Martínez, SRL',
                                detalle: 'Pendiente de revisión',
                                valor: '—',
                                chip: 'Pendiente',
                                chipColor: AppColors.warning,
                              ),
                              _ListaItem(
                                nombre: 'Comercializadora La Esperanza',
                                detalle: 'Aprobada',
                                valor: '—',
                                chip: 'Aprobada',
                                chipColor: AppColors.success,
                              ),
                              _ListaItem(
                                nombre: 'Grupo Industrial del Norte',
                                detalle: 'Pendiente de revisión',
                                valor: '—',
                                chip: 'Pendiente',
                                chipColor: AppColors.warning,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _ListaPanel(
                      title: 'Próximos vencimientos',
                      footerLabel: 'Ver todos los vencimientos →',
                      onFooter: () => context.push('/creditos/cuentas'),
                      children: const [
                        _ListaItem(
                          nombre: 'Cartera por vencer',
                          detalle: 'Consulta cuentas por cobrar',
                          valor: '—',
                          valorColor: AppColors.error,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ListaPanel(
                      title: 'Solicitudes recientes',
                      footerLabel: 'Ver todas las solicitudes →',
                      onFooter: () => context.push('/creditos/solicitudes'),
                      children: const [
                        _ListaItem(
                          nombre: 'Solicitudes de crédito',
                          detalle: 'Pendientes e historial',
                          valor: '—',
                          chip: 'Ver',
                          chipColor: AppColors.primary,
                        ),
                      ],
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

// ─────────────────────────────────────────────
// BANNER
// ─────────────────────────────────────────────
class _BannerCredito extends StatelessWidget {
  const _BannerCredito({required this.mobile});
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 18 : 24,
        vertical: mobile ? 16 : 20,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: mobile ? 44 : 52,
            height: mobile ? 44 : 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.credit_score_rounded,
              color: AppColors.primary,
              size: mobile ? 24 : 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de crédito',
                  style: (mobile ? AppTypography.h4 : AppTypography.h3).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Solicitudes, aprobación y cuentas por cobrar. Flujo: cotización → crédito → caja.',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.35,
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

// ─────────────────────────────────────────────
// KPI PILL
// ─────────────────────────────────────────────
class _KpiPill extends StatelessWidget {
  const _KpiPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: fg, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h4.copyWith(
                    fontWeight: FontWeight.w800,
                    color: fg,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.4,
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

// ─────────────────────────────────────────────
// OP CARD
// ─────────────────────────────────────────────
class _OpCard extends StatelessWidget {
  const _OpCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LISTA PANEL
// ─────────────────────────────────────────────
class _ListaPanel extends StatelessWidget {
  const _ListaPanel({
    required this.title,
    required this.footerLabel,
    required this.onFooter,
    required this.children,
  });

  final String title;
  final String footerLabel;
  final VoidCallback onFooter;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...children,
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onFooter,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                footerLabel,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListaItem extends StatelessWidget {
  const _ListaItem({
    required this.nombre,
    required this.detalle,
    required this.valor,
    this.valorColor,
    this.chip,
    this.chipColor,
  });

  final String nombre;
  final String detalle;
  final String valor;
  final Color? valorColor;
  final String? chip;
  final Color? chipColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.grey100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, size: 18, color: AppColors.grey600),
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
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  detalle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (chip != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (chipColor ?? AppColors.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                chip!,
                style: AppTypography.labelSmall.copyWith(
                  color: chipColor ?? AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            valor,
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: valorColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
