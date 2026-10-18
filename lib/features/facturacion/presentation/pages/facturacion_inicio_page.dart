import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:fiscogest_rd/features/facturacion/presentation/providers/facturacion_providers.dart';

/// Hub Facturación y NC — SaaS premium (ruta real /sales).
class FacturacionInicioPage extends ConsumerWidget {
  const FacturacionInicioPage({super.key});

  static const String routeName = 'sales';
  static const String path = '/sales';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simple =
        ref
            .watch(configuracionControllerProvider)
            .valueOrNull
            ?.modoSimplificado ==
        true;
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);

    final kpisAsync = ref.watch(facturacionKpisProvider);
    final kpis = kpisAsync.valueOrNull;
    final facturasHoyStr =
        kpisAsync.isLoading && kpis == null ? '…' : '${kpis?.facturasHoy ?? 0}';
    final ncHoyStr =
        kpisAsync.isLoading && kpis == null ? '…' : '${kpis?.ncHoy ?? 0}';
    final ncfDisponiblesStr = kpisAsync.isLoading && kpis == null
        ? '…'
        : '${kpis?.ncfDisponibles ?? 0}';
    final alertasStr =
        kpisAsync.isLoading && kpis == null ? '…' : '${kpis?.alertasNcf ?? 0}';

    return AppScaffold(
      title: simple ? 'VENTAS / COMPROBANTES' : 'FACTURACIÓN Y NC',
      showAppBar: !desktop, // Desktop: solo barra shell (como Dashboard)
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
                  if (desktop) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                simple ? 'Ventas / Comprobantes' : 'Facturación y NC',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                simple
                                    ? 'Comprobantes y operaciones del día.'
                                    : 'Emisión fiscal, notas de crédito y secuencias NCF.',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ] else ...[
                    _BannerFacturacion(mobile: mobile, simple: simple),
                    const SizedBox(height: 18),
                  ],

                  // KPIs (en modo simple se ocultan los fiscales de NC/NCF alert)
                  if (desktop)
                    Row(
                      children: [
                        Expanded(
                          child: _KpiPill(
                            icon: Icons.receipt_long_outlined,
                            value: facturasHoyStr,
                            label: 'FACTURAS HOY',
                            bg: const Color(0xFFECFDF5),
                            fg: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (!simple) ...[
                          Expanded(
                            child: _KpiPill(
                              icon: Icons.note_alt_outlined,
                              value: ncHoyStr,
                              label: 'NC HOY',
                              bg: const Color(0xFFEFF6FF),
                              fg: AppColors.info,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _KpiPill(
                              icon: Icons.qr_code_2_outlined,
                              value: ncfDisponiblesStr,
                              label: 'NCF DISPONIBLES',
                              bg: const Color(0xFFF5F3FF),
                              fg: const Color(0xFF7C3AED),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _KpiPill(
                              icon: Icons.warning_amber_rounded,
                              value: alertasStr,
                              label: 'ALERTAS NCF',
                              bg: const Color(0xFFFFF7ED),
                              fg: AppColors.warning,
                            ),
                          ),
                        ] else ...[
                          const Expanded(
                            child: _KpiPill(
                              icon: Icons.history_outlined,
                              value: '—',
                              label: 'HISTORIAL',
                              bg: Color(0xFFEFF6FF),
                              fg: AppColors.info,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: _KpiPill(
                              icon: Icons.point_of_sale_outlined,
                              value: '—',
                              label: 'COMPROBANTES',
                              bg: Color(0xFFF5F3FF),
                              fg: Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ],
                    )
                  else
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.45,
                      children: [
                        _KpiPill(
                          icon: Icons.receipt_long_outlined,
                          value: facturasHoyStr,
                          label: 'FACTURAS',
                          bg: const Color(0xFFECFDF5),
                          fg: AppColors.success,
                        ),
                        if (!simple) ...[
                          _KpiPill(
                            icon: Icons.note_alt_outlined,
                            value: ncHoyStr,
                            label: 'NC',
                            bg: const Color(0xFFEFF6FF),
                            fg: AppColors.info,
                          ),
                          _KpiPill(
                            icon: Icons.qr_code_2_outlined,
                            value: ncfDisponiblesStr,
                            label: 'NCF',
                            bg: const Color(0xFFF5F3FF),
                            fg: const Color(0xFF7C3AED),
                          ),
                          _KpiPill(
                            icon: Icons.warning_amber_rounded,
                            value: alertasStr,
                            label: 'ALERTAS',
                            bg: const Color(0xFFFFF7ED),
                            fg: AppColors.warning,
                          ),
                        ] else ...[
                          const _KpiPill(
                            icon: Icons.history_outlined,
                            value: '—',
                            label: 'HISTORIAL',
                            bg: Color(0xFFEFF6FF),
                            fg: AppColors.info,
                          ),
                        ],
                      ],
                    ),

                  const SizedBox(height: 22),

                  Text(
                    'Operaciones',
                    style: AppTypography.h4.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    simple ? 'Comprobantes de venta' : 'Comprobantes fiscales',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!simple) ...[
                          Expanded(
                            child: _OpCard(
                              icon: Icons.receipt_long_outlined,
                              title: 'Emitir factura',
                              subtitle:
                                  'Crea una factura con NCF de consumo o crédito fiscal',
                              color: AppColors.primary,
                              onTap: () =>
                                  context.push('/sales/emitir-factura'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _OpCard(
                              icon: Icons.note_alt_outlined,
                              title: 'Emitir NC',
                              subtitle:
                                  'Emite una nota de crédito sobre una factura',
                              color: const Color(0xFF6366F1),
                              onTap: () => context.push('/sales/emitir-nc'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      context.push('/sales/historial'),
                                  child: Text(
                                    'Historial →',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      context.push('/sales/secuencias-ncf'),
                                  child: Text(
                                    'Secuencias NCF →',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: _OpCard(
                              icon: Icons.history_outlined,
                              title: 'Historial',
                              subtitle: 'Consulta facturas y NC emitidas',
                              color: AppColors.primary,
                              onTap: () => context.push('/sales/historial'),
                            ),
                          ),
                        ],
                      ],
                    )
                  else ...[
                    if (!simple) ...[
                      _OpCard(
                        icon: Icons.receipt_long_outlined,
                        title: 'Emitir factura',
                        subtitle:
                            'Crea una factura con NCF de consumo o crédito fiscal',
                        color: AppColors.primary,
                        onTap: () => context.push('/sales/emitir-factura'),
                      ),
                      const SizedBox(height: 10),
                      _OpCard(
                        icon: Icons.note_alt_outlined,
                        title: 'Emitir NC',
                        subtitle: 'Emite una nota de crédito sobre una factura',
                        color: const Color(0xFF6366F1),
                        onTap: () => context.push('/sales/emitir-nc'),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => context.push('/sales/historial'),
                        child: Text(
                          'Historial →',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/sales/secuencias-ncf'),
                        child: Text(
                          'Secuencias NCF →',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ] else
                      _OpCard(
                        icon: Icons.history_outlined,
                        title: 'Historial',
                        subtitle: 'Consulta facturas y NC emitidas',
                        color: AppColors.primary,
                        onTap: () => context.push('/sales/historial'),
                      ),
                  ],

                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ListaPanel(
                            title: 'Últimos comprobantes',
                            footerLabel: 'Ver historial completo →',
                            onFooter: () => context.push('/sales/historial'),
                            children: const [
                              _ListaItem(
                                nombre: 'Factura B01',
                                detalle:
                                    'Consulta el historial para el detalle',
                                valor: '—',
                                chip: 'Factura',
                                chipColor: AppColors.primary,
                              ),
                              _ListaItem(
                                nombre: 'Nota de crédito',
                                detalle: 'Vinculada a factura',
                                valor: '—',
                                chip: 'NC',
                                chipColor: Color(0xFF6366F1),
                              ),
                              _ListaItem(
                                nombre: 'Comprobante fiscal',
                                detalle: 'NCF e impacto en inventario',
                                valor: '—',
                                chip: 'NCF',
                                chipColor: AppColors.info,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _ListaPanel(
                            title: 'Estado de secuencias',
                            footerLabel: 'Gestionar secuencias NCF →',
                            onFooter: () =>
                                context.push('/sales/secuencias-ncf'),
                            children: const [
                              _ListaItem(
                                nombre: 'B01 · Crédito fiscal',
                                detalle: 'Rango autorizado vs usado',
                                valor: '—',
                                chip: 'B01',
                                chipColor: AppColors.success,
                              ),
                              _ListaItem(
                                nombre: 'B02 · Consumidor final',
                                detalle: 'Rango autorizado vs usado',
                                valor: '—',
                                chip: 'B02',
                                chipColor: AppColors.info,
                              ),
                              _ListaItem(
                                nombre: 'B04 · Nota de crédito',
                                detalle: 'Rango autorizado vs usado',
                                valor: '—',
                                chip: 'B04',
                                chipColor: Color(0xFF7C3AED),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _ListaPanel(
                      title: 'Últimos comprobantes',
                      footerLabel: 'Ver historial completo →',
                      onFooter: () => context.push('/sales/historial'),
                      children: const [
                        _ListaItem(
                          nombre: 'Historial de facturas y NC',
                          detalle: 'Consulta comprobantes emitidos',
                          valor: '—',
                          chip: 'Ver',
                          chipColor: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ListaPanel(
                      title: 'Estado de secuencias',
                      footerLabel: 'Gestionar secuencias NCF →',
                      onFooter: () => context.push('/sales/secuencias-ncf'),
                      children: const [
                        _ListaItem(
                          nombre: 'Secuencias NCF',
                          detalle: 'B01 · B02 · B04',
                          valor: '—',
                          chip: 'NCF',
                          chipColor: Color(0xFF7C3AED),
                        ),
                      ],
                    ),
                  ],
                  if (!simple) ...[const SizedBox(height: 24)],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerFacturacion extends StatelessWidget {
  const _BannerFacturacion({required this.mobile, required this.simple});
  final bool mobile;
  final bool simple;

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
              Icons.receipt_long_rounded,
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
                  simple ? 'Ventas / Comprobantes' : 'Facturación y NC',
                  style: (mobile ? AppTypography.h4 : AppTypography.h3)
                      .copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  simple
                      ? 'Consulta comprobantes e historial de emisión.'
                      : 'Emisión de facturas, notas de crédito, NCF e historial de comprobantes.',
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
  final Color bg; // compatibilidad con llamadas existentes
  final Color fg;
  @override
  Widget build(BuildContext context) {
    final color = fg;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final iconBox = narrow ? 36.0 : 46.0;
    final iconSz = narrow ? 18.0 : 23.0;
    final padH = narrow ? 10.0 : 14.0;
    final padV = narrow ? 12.0 : 14.0;
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: Colors.white, size: iconSz),
            ),
            SizedBox(width: narrow ? 8 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: narrow ? 11 : 13,
                      color: color,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: narrow ? 16 : 18,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                        height: 1.1,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hoy',
                    style: TextStyle(
                      fontSize: narrow ? 11 : 12.5,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


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
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withValues(alpha: 0.08),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: Colors.white, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}


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
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
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
    this.chip,
    this.chipColor,
  });

  final String nombre;
  final String detalle;
  final String valor;
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
            child: const Icon(
              Icons.receipt_outlined,
              size: 18,
              color: AppColors.grey600,
            ),
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
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
