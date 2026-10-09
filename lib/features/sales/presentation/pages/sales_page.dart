import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';

/// Hub Facturación y NC — SaaS premium (mismo lenguaje que Crédito / Caja).
class SalesPage extends ConsumerWidget {
  const SalesPage({super.key});

  static const String routeName = 'sales';
  static const String path = '/sales';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);

    const facturasHoyStr = '—';
    const ncHoyStr = '—';
    const ncfDisponiblesStr = '—';
    const alertasStr = '—';

    return AppScaffold(
      title: 'FACTURACIÓN Y NC',
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
                  _BannerFacturacion(mobile: mobile),
                  const SizedBox(height: 18),
                  if (desktop)
                    const Row(
                      children: [
                        Expanded(
                          child: _KpiPill(
                            icon: Icons.receipt_long_outlined,
                            value: facturasHoyStr,
                            label: 'FACTURAS HOY',
                            bg: Color(0xFFECFDF5),
                            fg: AppColors.success,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _KpiPill(
                            icon: Icons.note_alt_outlined,
                            value: ncHoyStr,
                            label: 'NC HOY',
                            bg: Color(0xFFEFF6FF),
                            fg: AppColors.info,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _KpiPill(
                            icon: Icons.qr_code_2_outlined,
                            value: ncfDisponiblesStr,
                            label: 'NCF DISPONIBLES',
                            bg: Color(0xFFF5F3FF),
                            fg: Color(0xFF7C3AED),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _KpiPill(
                            icon: Icons.warning_amber_rounded,
                            value: alertasStr,
                            label: 'ALERTAS NCF',
                            bg: Color(0xFFFFF7ED),
                            fg: AppColors.warning,
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
                      children: const [
                        _KpiPill(
                          icon: Icons.receipt_long_outlined,
                          value: facturasHoyStr,
                          label: 'FACTURAS HOY',
                          bg: Color(0xFFECFDF5),
                          fg: AppColors.success,
                        ),
                        _KpiPill(
                          icon: Icons.note_alt_outlined,
                          value: ncHoyStr,
                          label: 'NC HOY',
                          bg: Color(0xFFEFF6FF),
                          fg: AppColors.info,
                        ),
                        _KpiPill(
                          icon: Icons.qr_code_2_outlined,
                          value: ncfDisponiblesStr,
                          label: 'NCF DISPONIBLES',
                          bg: Color(0xFFF5F3FF),
                          fg: Color(0xFF7C3AED),
                        ),
                        _KpiPill(
                          icon: Icons.warning_amber_rounded,
                          value: alertasStr,
                          label: 'ALERTAS NCF',
                          bg: Color(0xFFFFF7ED),
                          fg: AppColors.warning,
                        ),
                      ],
                    ),
                  const SizedBox(height: 22),
                  Text(
                    'Operaciones',
                    style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Comprobantes fiscales y secuencias NCF',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _OpCard(
                            icon: Icons.receipt_long_outlined,
                            title: 'Emitir factura',
                            subtitle: 'B01, B02 y comprobantes fiscales',
                            color: AppColors.primary,
                            onTap: () => context.push('/sales/emitir-factura'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OpCard(
                            icon: Icons.note_alt_outlined,
                            title: 'Emitir NC',
                            subtitle: 'Notas de crédito vinculadas a factura',
                            color: const Color(0xFF6366F1),
                            onTap: () => context.push('/sales/emitir-nc'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
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
                      ],
                    )
                  else ...[
                    _OpCard(
                      icon: Icons.receipt_long_outlined,
                      title: 'Emitir factura',
                      subtitle: 'B01, B02 y comprobantes fiscales',
                      color: AppColors.primary,
                      onTap: () => context.push('/sales/emitir-factura'),
                    ),
                    const SizedBox(height: 10),
                    _OpCard(
                      icon: Icons.note_alt_outlined,
                      title: 'Emitir NC',
                      subtitle: 'Notas de crédito vinculadas a factura',
                      color: const Color(0xFF6366F1),
                      onTap: () => context.push('/sales/emitir-nc'),
                    ),
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
                  ],
                  const SizedBox(height: 24),
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
                                detalle: 'Consulta el historial para el detalle',
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
  const _BannerFacturacion({required this.mobile});
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
                  'Facturación y NC',
                  style: (mobile ? AppTypography.h4 : AppTypography.h3).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Emisión de facturas, notas de crédito, NCF e historial de comprobantes.',
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
            style:
                AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800),
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
