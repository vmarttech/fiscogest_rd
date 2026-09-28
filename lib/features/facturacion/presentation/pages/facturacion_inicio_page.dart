import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';

class FacturacionInicioPage extends StatelessWidget {
  const FacturacionInicioPage({super.key});

  static const String routeName = 'sales';
  static const String path = '/sales';

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);

    return AppScaffold(
      title: 'FACTURACIÓN Y NC',
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
                  // Hero más grueso (estilo referencia)
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
                        Positioned(
                          right: 60,
                          bottom: -50,
                          child: IgnorePointer(
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
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
                            Icons.receipt_long_rounded,
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
                                'Facturación y NC',
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
                                'Emite, gestiona y consulta comprobantes '
                                'con NCF e historial.',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
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
                    subtitle: 'Comprobantes fiscales',
                  ),
                  const SizedBox(height: 14),
                  AppAccessGrid(
                    minTileWidth: 200,
                    maxColumns: 4,
                    spacing: 16,
                    runSpacing: 16,
                    tileHeight: mobile ? 200 : 200,
                    children: [
                      AppHubCard(
                        icon: Icons.note_add_outlined,
                        title: 'Emitir factura',
                        subtitle:
                            'Crea una factura con NCF de consumo o crédito fiscal',
                        color: AppColors.primary,
                        onTap: () => context.push('/sales/emitir-factura'),
                      ),
                      AppHubCard(
                        icon: Icons.assignment_return_outlined,
                        title: 'Emitir NC',
                        subtitle: 'Emite una nota de crédito sobre una factura',
                        color: AppColors.info,
                        onTap: () => context.push('/sales/emitir-nc'),
                      ),
                      AppHubCard(
                        icon: Icons.history_outlined,
                        title: 'Historial',
                        subtitle: 'Consulta facturas y NC emitidas',
                        color: AppColors.primary,
                        onTap: () => context.push('/sales/historial'),
                      ),
                      AppHubCard(
                        icon: Icons.pin_outlined,
                        title: 'Secuencias NCF',
                        subtitle: 'Gestiona secuencias y rangos autorizados',
                        color: AppColors.primary,
                        onTap: () => context.push('/sales/secuencias-ncf'),
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
