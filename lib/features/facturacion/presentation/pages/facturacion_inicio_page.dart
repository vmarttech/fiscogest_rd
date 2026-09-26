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
                    title: 'Facturación electrónica',
                    subtitle:
                        'Emite facturas y notas de crédito con NCF (B01, B02, B04) '
                        'y consulta el historial fiscal.',
                    icon: Icons.receipt_long_rounded,
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Operaciones',
                    subtitle: 'Comprobantes fiscales',
                  ),
                  const SizedBox(height: 8),
                  if (desktop)
                    Row(
                      children: [
                        Expanded(
                          child: AppAccessTile(
                            icon: Icons.note_add_outlined,
                            title: 'Emitir factura',
                            subtitle: 'NCF de consumo o crédito fiscal',
                            color: AppColors.primary,
                            onTap: () =>
                                context.push('/sales/emitir-factura'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppAccessTile(
                            icon: Icons.assignment_return_outlined,
                            title: 'Emitir NC',
                            subtitle: 'Nota de crédito sobre factura',
                            color: AppColors.warning,
                            onTap: () => context.push('/sales/emitir-nc'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppAccessTile(
                            icon: Icons.history_outlined,
                            title: 'Historial',
                            subtitle: 'Facturas y NC emitidas',
                            color: AppColors.info,
                            onTap: () => context.push('/sales/historial'),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    AppAccessTile(
                      icon: Icons.note_add_outlined,
                      title: 'Emitir factura',
                      subtitle: 'NCF de consumo o crédito fiscal',
                      color: AppColors.primary,
                      onTap: () => context.push('/sales/emitir-factura'),
                    ),
                    const SizedBox(height: 10),
                    AppAccessTile(
                      icon: Icons.assignment_return_outlined,
                      title: 'Emitir NC',
                      subtitle: 'Nota de crédito sobre factura',
                      color: AppColors.warning,
                      onTap: () => context.push('/sales/emitir-nc'),
                    ),
                    const SizedBox(height: 10),
                    AppAccessTile(
                      icon: Icons.history_outlined,
                      title: 'Historial',
                      subtitle: 'Facturas y NC emitidas',
                      color: AppColors.info,
                      onTap: () => context.push('/sales/historial'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  AppAccessTile(
                    icon: Icons.pin_outlined,
                    title: 'Secuencias NCF',
                    subtitle: 'Rangos y correlativos DGII',
                    color: AppColors.secondary,
                    onTap: () => context.push('/sales/secuencias-ncf'),
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
