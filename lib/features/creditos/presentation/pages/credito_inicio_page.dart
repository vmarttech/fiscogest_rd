import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';

/// Hub del área de Crédito (análogo al home de Caja).
class CreditoInicioPage extends ConsumerWidget {
  const CreditoInicioPage({super.key});

  static const String routeName = 'credito-inicio';
  static const String path = '/creditos';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);
    final maxW = desktop ? 1100 : (mobile ? 520 : 720);

    return AppScaffold(
      title: 'CRÉDITO',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppLayout.pantallaPadding.add(
            const EdgeInsets.only(bottom: 24),
          ),
          child: AppLayout.centerConstrained(
            maxWidth: maxW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  borderColor: AppColors.border,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Área de crédito',
                        style: AppTypography.h4.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      AppLayout.vXs,
                      Text(
                        'Depura clientes, ajusta condiciones, aprueba cotizaciones CR- '
                        'y deja el documento listo para Caja.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                AppLayout.vL,
                SectionHeader(
                  title: 'Operaciones',
                  subtitle: desktop ? 'Flujo cotización → crédito → caja' : null,
                ),
                if (desktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _accionSolicitudes(context)),
                      AppLayout.hM,
                      Expanded(child: _accionCxc(context)),
                      AppLayout.hM,
                      Expanded(child: _accionInfo(context)),
                    ],
                  )
                else ...[
                  _accionSolicitudes(context),
                  AppLayout.vS,
                  _accionCxc(context),
                  AppLayout.vS,
                  _accionInfo(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _accionSolicitudes(BuildContext context) {
    return _AccionCredito(
      icono: Icons.assignment_outlined,
      titulo: 'Solicitudes pendientes',
      subtitulo: 'Cotizaciones CR- en análisis (enCredito)',
      color: AppColors.warning,
      onTap: () => context.push('/creditos/solicitudes'),
    );
  }

  Widget _accionCxc(BuildContext context) {
    return _AccionCredito(
      icono: Icons.account_balance_wallet_outlined,
      titulo: 'Cuentas por cobrar',
      subtitulo: 'Saldos y seguimiento de clientes',
      color: AppColors.info,
      onTap: () => context.push('/creditos/cuentas'),
    );
  }

  Widget _accionInfo(BuildContext context) {
    return _AccionCredito(
      icono: Icons.settings_outlined,
      titulo: 'Configuración',
      subtitulo: 'Tasas, mora, plantillas de solicitud y contrato',
      color: AppColors.primary,
      onTap: () => context.push('/creditos/config'),
    );
  }
}

class _AccionCredito extends StatelessWidget {
  const _AccionCredito({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.onTap,
  }) : habilitado = true;

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final VoidCallback onTap;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    return Opacity(
      opacity: habilitado ? 1 : 0.55,
      child: AppCard(
        borderColor: AppColors.border,
        onTap: onTap,
        padding: EdgeInsets.symmetric(
          horizontal: mobile ? 14 : 16,
          vertical: mobile ? 14 : 18,
        ),
        child: Row(
          children: [
            Container(
              width: mobile ? 44 : 52,
              height: mobile ? 44 : 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: AppRadius.allM,
              ),
              child: Icon(icono, color: color, size: mobile ? 22 : 26),
            ),
            AppLayout.hM,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
