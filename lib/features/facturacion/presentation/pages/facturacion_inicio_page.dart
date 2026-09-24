import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';

/// Hub Facturación y NC (menú → /sales). Ancho controlado por AppLayout.
class FacturacionInicioPage extends StatelessWidget {
  const FacturacionInicioPage({super.key});

  static const String routeName = 'facturacion-inicio';
  static const String path = '/sales';

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);
    // Mismos topes que Crédito / resto del sistema
    final int maxW = desktop ? 1100 : (mobile ? 520 : 720);

    return AppScaffold(
      title: 'FACTURACIÓN Y NC',
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
        child: Align(
          alignment: Alignment.topCenter,
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
                          'Comprobantes fiscales',
                          style: AppTypography.h4.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        AppLayout.vXs,
                        Text(
                          'Emisión de facturas (NCF) y notas de crédito. '
                          'Las cotizaciones se generan en Ventas; el cobro en Caja.',
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
                    subtitle:
                        desktop ? 'Factura · NC · historial · secuencias' : null,
                  ),
                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _accionEmitirFactura(context)),
                        AppLayout.hM,
                        Expanded(child: _accionEmitirNc(context)),
                        AppLayout.hM,
                        Expanded(child: _accionHistorial(context)),
                      ],
                    )
                  else ...[
                    _accionEmitirFactura(context),
                    AppLayout.vS,
                    _accionEmitirNc(context),
                    AppLayout.vS,
                    _accionHistorial(context),
                  ],
                  AppLayout.vS,
                  _accionSecuencias(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _accionEmitirFactura(BuildContext context) {
    return _AccionFacturacion(
      icono: Icons.receipt_long_outlined,
      titulo: 'Emitir factura',
      subtitulo: 'Desde cotización o venta lista (próximamente)',
      color: AppColors.primary,
      onTap: () => context.push('/sales/emitir-factura'),
    );
  }

  Widget _accionEmitirNc(BuildContext context) {
    return _AccionFacturacion(
      icono: Icons.note_alt_outlined,
      titulo: 'Emitir nota de crédito',
      subtitulo: 'Anulación o ajuste de factura (próximamente)',
      color: AppColors.warning,
      onTap: () => context.push('/sales/emitir-nc'),
    );
  }

  Widget _accionHistorial(BuildContext context) {
    return _AccionFacturacion(
      icono: Icons.history,
      titulo: 'Historial de facturas',
      subtitulo: 'Consultar y reimprimir',
      color: AppColors.info,
      onTap: () => context.push('/sales/historial'),
    );
  }

  Widget _accionSecuencias(BuildContext context) {
    return _AccionFacturacion(
      icono: Icons.pin_outlined,
      titulo: 'Secuencias NCF',
      subtitulo: 'Rangos autorizados por tipo de comprobante',
      color: AppColors.primary,
      onTap: () => context.push('/sales/secuencias-ncf'),
    );
  }
}

class _AccionFacturacion extends StatelessWidget {
  const _AccionFacturacion({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    return AppCard(
      borderColor: AppColors.border,
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 14 : 16,
        vertical: mobile ? 14 : 16,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: color, size: 24),
          ),
          SizedBox(width: mobile ? 12 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
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
          const Icon(Icons.chevron_right, color: AppColors.grey600),
        ],
      ),
    );
  }
}
