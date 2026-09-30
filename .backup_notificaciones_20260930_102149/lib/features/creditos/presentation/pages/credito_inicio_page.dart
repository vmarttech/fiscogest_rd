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
              mobile ? 16 : 20,
              mobile ? 16 : 20,
              mobile ? 16 : 20,
              32,
            ),
            child: AppLayout.centerConstrained(
              maxWidth: desktop ? 1800 : 9999,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      mobile ? 20 : 28,
                      mobile ? 22 : 28,
                      mobile ? 20 : 28,
                      mobile ? 22 : 28,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppColors.primaryDark,
                          AppColors.primary,
                          AppColors.primaryLight.withValues(alpha: 0.95),
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
                    child: Stack(
                      children: [
                        Positioned(
                          right: -30,
                          top: -40,
                          child: IgnorePointer(
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.07),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: mobile ? 56 : 64,
                              height: mobile ? 56 : 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.credit_score_rounded,
                                color: AppColors.primary,
                                size: mobile ? 30 : 34,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gestión de crédito',
                                    style: (mobile
                                            ? AppTypography.h4
                                            : AppTypography.h3)
                                        .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Solicitudes, aprobación y cuentas por cobrar. '
                                    'Flujo: cotización → crédito → caja.',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const SectionHeader(
                    title: 'Operaciones',
                    subtitle: 'Cartera y políticas',
                  ),
                  const SizedBox(height: 14),
                  AppAccessGrid(
                    minTileWidth: 200,
                    maxColumns: 3,
                    spacing: 16,
                    runSpacing: 16,
                    tileHeight: mobile ? 200 : 200,
                    children: [
                      AppHubCard(
                        icon: Icons.assignment_outlined,
                        title: 'Solicitudes',
                        subtitle: 'Pendientes, historial y aprobación',
                        color: AppColors.primary,
                        onTap: () => context.push('/creditos/solicitudes'),
                      ),
                      AppHubCard(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Cuentas por cobrar',
                        subtitle: 'Saldos, cuotas y cobros',
                        color: AppColors.success,
                        onTap: () => context.push('/creditos/cuentas'),
                      ),
                      AppHubCard(
                        icon: Icons.tune_outlined,
                        title: 'Configuración',
                        subtitle: 'Plazos, tasas y políticas',
                        color: AppColors.secondary,
                        onTap: () => context.push('/creditos/config'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
