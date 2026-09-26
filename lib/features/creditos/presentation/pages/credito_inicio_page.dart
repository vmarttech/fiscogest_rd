import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';

class CreditoInicioPage extends StatelessWidget {
  const CreditoInicioPage({super.key});

  static const String routeName = 'creditos';
  static const String path = '/creditos';

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);

    return AppScaffold(
      title: 'CRÉDITO',
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              mobile ? 16 : 8,
              mobile ? 16 : 20,
              mobile ? 16 : 8,
              32,
            ),
            child: AppLayout.centerConstrained(
              maxWidth: desktop ? 1320 : (mobile ? 520 : 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HubHero(
                    title: 'Gestión de crédito',
                    subtitle:
                        'Solicitudes, aprobación y cuentas por cobrar. '
                        'Flujo: cotización → crédito → caja.',
                    icon: Icons.credit_score_rounded,
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Operaciones',
                    subtitle: 'Cartera y políticas',
                  ),
                  const SizedBox(height: 8),
                  if (desktop)
                    Row(
                      children: [
                        Expanded(
                          child: AppAccessTile(
                            icon: Icons.assignment_outlined,
                            title: 'Solicitudes',
                            subtitle: 'Pendientes y historial',
                            color: AppColors.primary,
                            onTap: () =>
                                context.push('/creditos/solicitudes'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppAccessTile(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Cuentas por cobrar',
                            subtitle: 'Saldos y cobros',
                            color: AppColors.success,
                            onTap: () => context.push('/creditos/cuentas'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppAccessTile(
                            icon: Icons.tune_outlined,
                            title: 'Configuración',
                            subtitle: 'Plazos y políticas',
                            color: AppColors.secondary,
                            onTap: () => context.push('/creditos/config'),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    AppAccessTile(
                      icon: Icons.assignment_outlined,
                      title: 'Solicitudes',
                      subtitle: 'Pendientes y historial',
                      color: AppColors.primary,
                      onTap: () => context.push('/creditos/solicitudes'),
                    ),
                    const SizedBox(height: 10),
                    AppAccessTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Cuentas por cobrar',
                      subtitle: 'Saldos y cobros',
                      color: AppColors.success,
                      onTap: () => context.push('/creditos/cuentas'),
                    ),
                    const SizedBox(height: 10),
                    AppAccessTile(
                      icon: Icons.tune_outlined,
                      title: 'Configuración',
                      subtitle: 'Plazos y políticas',
                      color: AppColors.secondary,
                      onTap: () => context.push('/creditos/config'),
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

class _HubHero extends StatelessWidget {
  const _HubHero({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.primaryLight.withValues(alpha: 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
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
