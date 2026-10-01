import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

/// Hub de reportes DGII 606 (compras) y 607 (ventas).
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  static const String routeName = 'reportes';
  static const String path = '/reports';

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);

    return AppScaffold(
      title: 'REPORTES',
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
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: mobile ? 720 : 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Reportes 606 / 607',
                    style: AppTypography.h4.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Declaraciones DGII de compras y ventas del período.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: mobile ? 16 : 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Elija el tipo de reporte. La generación del archivo DGII se conectará en el siguiente paso.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: mobile ? 14 : 18),
                  if (mobile) ...[
                    _ReporteCard(
                      codigo: '606',
                      titulo: 'Compras',
                      subtitulo:
                          'Proveedores, NCF y montos del período (formato DGII).',
                      icon: Icons.shopping_cart_outlined,
                      color: AppColors.primary,
                      onTap: () => _aviso(context, '606'),
                    ),
                    const SizedBox(height: 12),
                    _ReporteCard(
                      codigo: '607',
                      titulo: 'Ventas',
                      subtitulo:
                          'Clientes, NCF y montos facturados del período.',
                      icon: Icons.point_of_sale_outlined,
                      color: AppColors.success,
                      onTap: () => _aviso(context, '607'),
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ReporteCard(
                            codigo: '606',
                            titulo: 'Compras',
                            subtitulo:
                                'Proveedores, NCF y montos del período (formato DGII).',
                            icon: Icons.shopping_cart_outlined,
                            color: AppColors.primary,
                            onTap: () => _aviso(context, '606'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _ReporteCard(
                            codigo: '607',
                            titulo: 'Ventas',
                            subtitulo:
                                'Clientes, NCF y montos facturados del período.',
                            icon: Icons.point_of_sale_outlined,
                            color: AppColors.success,
                            onTap: () => _aviso(context, '607'),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: mobile ? 20 : 24),
                  Text(
                    'Accesos relacionados',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _LinkTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Facturación y NC',
                    subtitle: 'NCF, notas de crédito y secuencias',
                    onTap: () => context.push('/sales'),
                  ),
                  const SizedBox(height: 10),
                  _LinkTile(
                    icon: Icons.calculate_outlined,
                    title: 'Impuestos',
                    subtitle: 'Tasas ITBIS y exenciones',
                    onTap: () => context.push('/impuestos'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _aviso(BuildContext context, String codigo) {
    FiscoGestNotifications.show(
      SnackBar(
        content: Text('Reporte $codigo: generación en construcción. UI lista.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ReporteCard extends StatelessWidget {
  const _ReporteCard({
    required this.codigo,
    required this.titulo,
    required this.subtitulo,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String codigo;
  final String titulo;
  final String subtitulo;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      codigo,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                titulo,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitulo,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Abrir',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
