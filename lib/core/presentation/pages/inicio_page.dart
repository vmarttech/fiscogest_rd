import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';

/// Hub de inicio — layout denso y atmósfera premium en desktop.
class InicioPage extends ConsumerWidget {
  const InicioPage({super.key});

  static const String routeName = 'inicio';
  static const String path = '/';

  String _saludo() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  void _go(BuildContext context, String ruta) {
    try {
      context.go(ruta);
    } catch (_) {
      context.push(ruta);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);
    final fecha = DateFormat("EEEE d 'de' MMMM yyyy", 'es').format(DateTime.now());

    return AppScaffold(
      title: 'INICIO',
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
                  Builder(
                    builder: (_) {
                      final cfg =
                          ref.watch(configuracionControllerProvider).valueOrNull;
                      final n1 = cfg?.nombreComercial.trim() ?? '';
                      final n2 = cfg?.razonSocial.trim() ?? '';
                      final nombre =
                          n1.isNotEmpty ? n1 : (n2.isNotEmpty ? n2 : 'Mi negocio');
                      return _HeroBanner(
                        saludo: _saludo(),
                        fecha: fecha,
                        nombreNegocio: nombre,
                        onNuevaVenta: () =>
                            _go(context, '/ventas/cotizaciones/nueva'),
                        onCaja: () => _go(context, '/ventas/cobro'),
                        compact: mobile,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // KPIs — llenan el ancho
                  if (desktop)
                    Row(
                      children: [
                        const Expanded(
                          child: _KpiTile(
                            label: 'Operación',
                            value: 'Hoy',
                            hint: 'Cotiza · Factura · Cobra',
                            icon: Icons.bolt_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KpiTile(
                            label: 'Caja',
                            value: 'Turno',
                            hint: 'Cobros y cierre',
                            icon: Icons.payments_outlined,
                            color: AppColors.success,
                            onTap: () => _go(context, '/ventas/cobro'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KpiTile(
                            label: 'Crédito',
                            value: 'CxC',
                            hint: 'Solicitudes y cobro',
                            icon: Icons.credit_score_outlined,
                            color: AppColors.warning,
                            onTap: () => _go(context, '/creditos'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KpiTile(
                            label: 'Stock',
                            value: 'Inv.',
                            hint: 'Existencias y kárdex',
                            icon: Icons.inventory_2_outlined,
                            color: AppColors.info,
                            onTap: () => _go(context, '/inventario'),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      height: 104,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          SizedBox(
                            width: 160,
                            child: _KpiTile(
                              label: 'Caja',
                              value: 'Turno',
                              hint: 'Cobros',
                              icon: Icons.payments_outlined,
                              color: AppColors.success,
                              onTap: () => _go(context, '/ventas/cobro'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 160,
                            child: _KpiTile(
                              label: 'Crédito',
                              value: 'CxC',
                              hint: 'Cartera',
                              icon: Icons.credit_score_outlined,
                              color: AppColors.warning,
                              onTap: () => _go(context, '/creditos'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 160,
                            child: _KpiTile(
                              label: 'Stock',
                              value: 'Inv.',
                              hint: 'Existencias',
                              icon: Icons.inventory_2_outlined,
                              color: AppColors.info,
                              onTap: () => _go(context, '/inventario'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Dos columnas en desktop
                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SectionHeader(
                                title: 'Accesos rápidos',
                                subtitle: 'Operación del día',
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _Acceso(
                                      icon: Icons.point_of_sale,
                                      titulo: 'Ventas',
                                      sub: 'Cotizaciones y pedidos',
                                      color: AppColors.primary,
                                      onTap: () => _go(context, '/ventas'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _Acceso(
                                      icon: Icons.payments_outlined,
                                      titulo: 'Caja',
                                      sub: 'Cobrar y turnos',
                                      color: AppColors.success,
                                      onTap: () => _go(context, '/ventas/cobro'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _Acceso(
                                      icon: Icons.receipt_long_outlined,
                                      titulo: 'Facturación',
                                      sub: 'NCF B01 / B02 / B04',
                                      color: AppColors.info,
                                      onTap: () => _go(context, '/sales'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _Acceso(
                                      icon: Icons.credit_score_outlined,
                                      titulo: 'Crédito',
                                      sub: 'Solicitudes y CxC',
                                      color: AppColors.warning,
                                      onTap: () => _go(context, '/creditos'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _Acceso(
                                      icon: Icons.people_outline,
                                      titulo: 'Clientes',
                                      sub: 'Cartera',
                                      color: AppColors.primary,
                                      onTap: () => _go(context, '/clientes'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _Acceso(
                                      icon: Icons.inventory_2_outlined,
                                      titulo: 'Inventario',
                                      sub: 'Existencias',
                                      color: AppColors.info,
                                      onTap: () => _go(context, '/inventario'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SectionHeader(
                                title: 'Hoy en el negocio',
                                subtitle: 'Atajos y foco',
                              ),
                              const SizedBox(height: 8),
                              AppCard(
                                accent: true,
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Flujo recomendado',
                                      style: AppTypography.labelLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const _Paso(n: '1', t: 'Ventas → cotización'),
                                    const _Paso(n: '2', t: 'Crédito (si aplica)'),
                                    const _Paso(n: '3', t: 'Facturación → NCF'),
                                    const _Paso(n: '4', t: 'Caja → cobro'),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed: () =>
                                            _go(context, '/ventas/cotizaciones/nueva'),
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('Nueva cotización'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    const SectionHeader(title: 'Accesos rápidos'),
                    const SizedBox(height: 8),
                    _Acceso(
                      icon: Icons.point_of_sale,
                      titulo: 'Ventas',
                      sub: 'Cotizaciones y pedidos',
                      color: AppColors.primary,
                      onTap: () => _go(context, '/ventas'),
                    ),
                    const SizedBox(height: 10),
                    _Acceso(
                      icon: Icons.payments_outlined,
                      titulo: 'Caja',
                      sub: 'Cobrar y turnos',
                      color: AppColors.success,
                      onTap: () => _go(context, '/ventas/cobro'),
                    ),
                    const SizedBox(height: 10),
                    _Acceso(
                      icon: Icons.receipt_long_outlined,
                      titulo: 'Facturación',
                      sub: 'NCF B01 / B02 / B04',
                      color: AppColors.info,
                      onTap: () => _go(context, '/sales'),
                    ),
                    const SizedBox(height: 10),
                    _Acceso(
                      icon: Icons.credit_score_outlined,
                      titulo: 'Crédito',
                      sub: 'Solicitudes y CxC',
                      color: AppColors.warning,
                      onTap: () => _go(context, '/creditos'),
                    ),
                    const SizedBox(height: 10),
                    _Acceso(
                      icon: Icons.people_outline,
                      titulo: 'Clientes',
                      sub: 'Cartera',
                      color: AppColors.primary,
                      onTap: () => _go(context, '/clientes'),
                    ),
                    const SizedBox(height: 10),
                    _Acceso(
                      icon: Icons.inventory_2_outlined,
                      titulo: 'Inventario',
                      sub: 'Existencias',
                      color: AppColors.info,
                      onTap: () => _go(context, '/inventario'),
                    ),
                    const SizedBox(height: 20),
                    const SectionHeader(title: 'Flujo recomendado'),
                    const SizedBox(height: 8),
                    const AppCard(
                      child: Column(
                        children: [
                          _Paso(n: '1', t: 'Ventas → cotización'),
                          _Paso(n: '2', t: 'Crédito (si aplica)'),
                          _Paso(n: '3', t: 'Facturación → NCF'),
                          _Paso(n: '4', t: 'Caja → cobro'),
                        ],
                      ),
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

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.saludo,
    required this.fecha,
    required this.nombreNegocio,
    required this.onNuevaVenta,
    required this.onCaja,
    required this.compact,
  });

  final String saludo;
  final String fecha;
  final String nombreNegocio;
  final VoidCallback onNuevaVenta;
  final VoidCallback onCaja;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 28,
        compact ? 20 : 26,
        compact ? 20 : 28,
        compact ? 20 : 26,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.primaryLight.withValues(alpha: 0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -30,
            child: IgnorePointer(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -40,
            child: IgnorePointer(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                saludo,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                nombreNegocio,
                style: AppTypography.h2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                fecha,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Cotiza, facture con NCF, cobre en caja y gestione crédito '
                'desde un solo lugar.',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.35,
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: onNuevaVenta,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nueva cotización'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: onCaja,
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: const Text('Ir a caja'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  label.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.h4.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
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

class _Acceso extends StatelessWidget {
  const _Acceso({
    required this.icon,
    required this.titulo,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String titulo;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
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
                  titulo,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  sub,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppColors.grey400),
        ],
      ),
    );
  }
}

class _Paso extends StatelessWidget {
  const _Paso({required this.n, required this.t});

  final String n;
  final String t;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              n,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(t, style: AppTypography.bodySmall),
          ),
        ],
      ),
    );
  }
}
