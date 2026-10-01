import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:fiscogest_rd/features/reportes/domain/kpi_models.dart';
import 'package:fiscogest_rd/features/reportes/presentation/providers/dashboard_providers.dart';

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
    context.push(ruta);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);
    final modoCfg = ref.watch(modoSimplificadoProvider);
    final sesion = ref.watch(sesionProvider);
    final esAdmin = sesion?.esAdmin ?? false;
    // Dashboard colmado solo Admin + config simplificada
    final simplificado = modoCfg && esAdmin;
    final fecha = DateFormat(
      "EEEE d 'de' MMMM yyyy",
      'es',
    ).format(DateTime.now());
    final cfgDash = ref.watch(configuracionControllerProvider).valueOrNull;
    final n1Dash = cfgDash?.nombreComercial.trim() ?? '';
    final n2Dash = cfgDash?.razonSocial.trim() ?? '';
    final nombreNegocioDash = n1Dash.isNotEmpty
        ? n1Dash
        : (n2Dash.isNotEmpty ? n2Dash : 'Mi negocio');

    // Dashboard EXCLUSIVO modo simplificado (colmadero)
    if (simplificado) {
      return AppScaffold(
        title: 'INICIO',
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                mobile ? 16 : 20,
                mobile ? 12 : 20,
                mobile ? 16 : 20,
                32,
              ),
              child: AppLayout.centerConstrained(
                maxWidth: desktop ? 900 : (mobile ? 520 : 720),
                child: _DashboardColmado(
                  mobile: mobile,
                  desktop: desktop,
                  saludo: _saludo(),
                  fecha: fecha,
                  nombreNegocio: nombreNegocioDash,
                  onNuevaVenta: () =>
                      _go(context, '/ventas/cotizaciones/nueva'),
                  onCaja: () => _go(context, '/ventas/cobro'),
                  onProveedores: () => _go(context, '/proveedores'),
                  onFiao: () => _go(context, '/ventas/fios'),
                  onProductos: () => _go(context, '/inventario'),
                  onCompras: () => _go(context, '/compras'),
                  onClientes: () => _go(context, '/clientes'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AppScaffold(
      title: 'INICIO',
      body: _FondoFuturista(
        child: SafeArea(
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
                        final cfg = ref
                            .watch(configuracionControllerProvider)
                            .valueOrNull;
                        final n1 = cfg?.nombreComercial.trim() ?? '';
                        final n2 = cfg?.razonSocial.trim() ?? '';
                        final nombre = n1.isNotEmpty
                            ? n1
                            : (n2.isNotEmpty ? n2 : 'Mi negocio');
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
                    // KPIs
                    if (simplificado)
                      _KpisSimplificado(
                        mobile: mobile,
                        desktop: desktop,
                        onCaja: () => _go(context, '/ventas/cobro'),
                        onFiao: () => _go(context, '/ventas/fios'),
                        onStock: () => _go(context, '/inventario'),
                      )
                    else if (desktop)
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
                      // Móvil: 2+1 evita ancho <30px y overflow vertical
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _KpiTile(
                                  label: 'Caja',
                                  value: 'Turno',
                                  hint: 'Cobros',
                                  icon: Icons.payments_outlined,
                                  color: AppColors.success,
                                  onTap: () => _go(context, '/ventas/cobro'),
                                  compact: true,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _KpiTile(
                                  label: 'Crédito',
                                  value: 'CxC',
                                  hint: 'Cartera',
                                  icon: Icons.credit_score_outlined,
                                  color: AppColors.warning,
                                  onTap: () => _go(context, '/creditos'),
                                  compact: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _KpiTile(
                            label: 'Stock',
                            value: 'Inventario',
                            hint: 'Existencias y kárdex',
                            icon: Icons.inventory_2_outlined,
                            color: AppColors.info,
                            onTap: () => _go(context, '/inventario'),
                            compact: true,
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    // Accesos
                    if (simplificado)
                      _AccesosSimplificado(
                        mobile: mobile,
                        desktop: desktop,
                        onProveedores: () => _go(context, '/proveedores'),
                        onCaja: () => _go(context, '/ventas/cobro'),
                        onFiao: () => _go(context, '/ventas/fios'),
                        onProductos: () => _go(context, '/inventario'),
                        onCompras: () => _go(context, '/compras'),
                        onClientes: () => _go(context, '/clientes'),
                        onNuevaVenta: () =>
                            _go(context, '/ventas/cotizaciones/nueva'),
                      )
                    else if (desktop)
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
                                        onTap: () =>
                                            _go(context, '/ventas/cobro'),
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
                                        onTap: () =>
                                            _go(context, '/inventario'),
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
                                  subtitle: 'Indicadores en vivo',
                                ),
                                const SizedBox(height: 8),
                                _InsightsCarousel(
                                  onNuevaCotizacion: () => _go(
                                    context,
                                    '/ventas/cotizaciones/nueva',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      Text(
                        'Operación del día',
                        style: AppTypography.h4.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lo esencial, al alcance',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Grilla 2×2 (mismo ritmo que modo simplificado)
                      Row(
                        children: [
                          Expanded(
                            child: _Acceso(
                              icon: Icons.point_of_sale,
                              titulo: 'Ventas',
                              sub: 'Cotizar y cobrar',
                              color: AppColors.primary,
                              onTap: () => _go(context, '/ventas'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Acceso(
                              icon: Icons.payments_outlined,
                              titulo: 'Caja',
                              sub: 'Turno y cobros',
                              color: AppColors.success,
                              onTap: () => _go(context, '/ventas/cobro'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _Acceso(
                              icon: Icons.receipt_long_outlined,
                              titulo: 'Facturación',
                              sub: 'NCF y docs',
                              color: AppColors.info,
                              onTap: () => _go(context, '/sales'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Acceso(
                              icon: Icons.inventory_2_outlined,
                              titulo: 'Inventario',
                              sub: 'Stock',
                              color: AppColors.warning,
                              onTap: () => _go(context, '/inventario'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _Acceso(
                        icon: Icons.more_horiz_rounded,
                        titulo: 'Más acciones',
                        sub: 'Crédito · Clientes · Proveedores',
                        color: const Color(0xFF64748B),
                        onTap: () => _mostrarMasAccionesNormal(context),
                      ),
                      const SizedBox(height: 20),
                      const SectionHeader(
                        title: 'Hoy en el negocio',
                        subtitle: 'Indicadores en vivo',
                      ),
                      const SizedBox(height: 8),
                      _InsightsCarousel(
                        onNuevaCotizacion: () =>
                            _go(context, '/ventas/cotizaciones/nueva'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarMasAccionesNormal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        Widget tile(
          IconData icon,
          String title,
          String sub,
          Color color,
          String route,
        ) {
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            title: Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              sub,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            onTap: () {
              Navigator.pop(ctx);
              context.go(route);
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Más acciones',
                  style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                tile(
                  Icons.credit_score_outlined,
                  'Crédito',
                  'Solicitudes y CxC',
                  AppColors.warning,
                  '/creditos',
                ),
                tile(
                  Icons.people_outline,
                  'Clientes',
                  'Cartera y fichas',
                  AppColors.primary,
                  '/clientes',
                ),
                tile(
                  Icons.local_shipping_outlined,
                  'Proveedores',
                  'Compras y CxP',
                  AppColors.info,
                  '/proveedores',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Dashboard completo solo para modo simplificado (negocio informal).
class _DashboardColmado extends StatelessWidget {
  const _DashboardColmado({
    required this.mobile,
    required this.desktop,
    required this.saludo,
    required this.fecha,
    required this.nombreNegocio,
    required this.onNuevaVenta,
    required this.onCaja,
    required this.onProveedores,
    required this.onFiao,
    required this.onProductos,
    required this.onCompras,
    required this.onClientes,
  });

  final bool mobile;
  final bool desktop;
  final String saludo;
  final String fecha;
  final String nombreNegocio;
  final VoidCallback onNuevaVenta;
  final VoidCallback onCaja;
  final VoidCallback onProveedores;
  final VoidCallback onFiao;
  final VoidCallback onProductos;
  final VoidCallback onCompras;
  final VoidCallback onClientes;

  @override
  Widget build(BuildContext context) {
    final cols = desktop ? 3 : 2;
    final items = <(IconData, String, String, Color, VoidCallback)>[
      (
        Icons.business_outlined,
        'Proveedores',
        'Mis proveedores',
        AppColors.primary,
        onProveedores,
      ),
      (
        Icons.payments_rounded,
        'Caja',
        'Cobros del día',
        AppColors.success,
        onCaja,
      ),
      (
        Icons.edit_note_rounded,
        'Fiao',
        'Lo que me deben',
        AppColors.warning,
        onFiao,
      ),
      (
        Icons.inventory_2_rounded,
        'Productos',
        'Existencias',
        AppColors.info,
        onProductos,
      ),
      (
        Icons.shopping_cart_rounded,
        'Compras',
        'Al proveedor',
        AppColors.primary,
        onCompras,
      ),
      (
        Icons.people_rounded,
        'Clientes',
        'Mis clientes',
        AppColors.primary,
        onClientes,
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        // 1) Degradado vertical de marca
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.10),
            AppColors.pageBackground,
            AppColors.pageBackground,
          ],
          stops: const [0.0, 0.38, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // 2) Halo radial detrás del hero
          Positioned(
            top: -40,
            left: -30,
            right: -30,
            height: 220,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 0.95,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.14),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // 3) Puntos sutiles (textura)
          Positioned.fill(
            child: CustomPaint(
              painter: _FondoPuntosPainter(
                color: AppColors.primary.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Contenido
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(
                  mobile ? 16 : 20,
                  mobile ? 14 : 18,
                  mobile ? 16 : 20,
                  mobile ? 14 : 18,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(mobile ? 16 : 20),
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
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      saludo,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: mobile ? 13 : 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nombreNegocio,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: mobile ? 20 : 24,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fecha,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(height: mobile ? 14 : 16),
                    SizedBox(
                      width: double.infinity,
                      height: mobile ? 48 : 52,
                      child: ElevatedButton.icon(
                        onPressed: onNuevaVenta,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryDark,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.add_shopping_cart_rounded),
                        label: const Text(
                          'NUEVA VENTA',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: mobile ? 18 : 22),
              Text(
                'Accesos del día',
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: mobile ? 16 : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Todo lo que usas en el mostrador',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: mobile ? 12 : 14),
              LayoutBuilder(
                builder: (context, c) {
                  final gap = mobile ? 10.0 : 12.0;
                  final w = (c.maxWidth - gap * (cols - 1)) / cols;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final e in items)
                        SizedBox(
                          width: w,
                          child: Material(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: e.$5,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: e.$4.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(e.$1, color: e.$4, size: 20),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      e.$2,
                                      style: AppTypography.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: mobile ? 14 : 15,
                                      ),
                                    ),
                                    Text(
                                      e.$3,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// KPIs del colmadero (modo simplificado).
class _KpisSimplificado extends StatelessWidget {
  const _KpisSimplificado({
    required this.mobile,
    required this.desktop,
    required this.onCaja,
    required this.onFiao,
    required this.onStock,
  });
  final bool mobile;
  final bool desktop;
  final VoidCallback onCaja;
  final VoidCallback onFiao;
  final VoidCallback onStock;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _KpiTile(
        label: 'Caja',
        value: 'Hoy',
        hint: 'Cobrar',
        icon: Icons.payments_outlined,
        color: AppColors.success,
        onTap: onCaja,
      ),
      _KpiTile(
        label: 'Fiao',
        value: 'Deudas',
        hint: 'Lo que me deben',
        icon: Icons.edit_note_rounded,
        color: AppColors.warning,
        onTap: onFiao,
      ),
      _KpiTile(
        label: 'Stock',
        value: 'Inv.',
        hint: 'Productos',
        icon: Icons.inventory_2_outlined,
        color: AppColors.info,
        onTap: onStock,
      ),
    ];
    if (desktop) {
      return Row(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: tiles[i]),
          ],
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: SizedBox(height: 100, child: tiles[i])),
        ],
      ],
    );
  }
}

/// Accesos del colmadero: 2 cols móvil/tablet, 3 en desktop.
class _AccesosSimplificado extends StatelessWidget {
  const _AccesosSimplificado({
    required this.mobile,
    required this.desktop,
    required this.onProveedores,
    required this.onCaja,
    required this.onFiao,
    required this.onProductos,
    required this.onCompras,
    required this.onClientes,
    required this.onNuevaVenta,
  });
  final bool mobile;
  final bool desktop;
  final VoidCallback onProveedores;
  final VoidCallback onCaja;
  final VoidCallback onFiao;
  final VoidCallback onProductos;
  final VoidCallback onCompras;
  final VoidCallback onClientes;
  final VoidCallback onNuevaVenta;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String, Color, VoidCallback)>[
      (
        Icons.business_outlined,
        'Proveedores',
        'Mis proveedores',
        AppColors.primary,
        onProveedores,
      ),
      (
        Icons.payments_outlined,
        'Caja',
        'Turno del día',
        AppColors.success,
        onCaja,
      ),
      (
        Icons.edit_note_rounded,
        'Fiao',
        'Lo que me deben',
        AppColors.warning,
        onFiao,
      ),
      (
        Icons.inventory_2_outlined,
        'Productos',
        'Existencias',
        AppColors.info,
        onProductos,
      ),
      (
        Icons.shopping_cart_outlined,
        'Compras',
        'Proveedores',
        AppColors.primary,
        onCompras,
      ),
      (
        Icons.people_outline,
        'Clientes',
        'Cartera',
        AppColors.primary,
        onClientes,
      ),
    ];
    final cols = desktop ? 3 : 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Accesos rápidos',
          subtitle: 'Lo del día a día',
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, c) {
            const gap = 10.0;
            final w = (c.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final e in items)
                  SizedBox(
                    width: w,
                    child: _Acceso(
                      icon: e.$1,
                      titulo: e.$2,
                      sub: e.$3,
                      color: e.$4,
                      onTap: e.$5,
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: mobile ? 52 : 56,
          child: ElevatedButton.icon(
            onPressed: onNuevaVenta,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text(
              'NUEVA VENTA',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
            ),
          ),
        ),
      ],
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
    this.compact = false,
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

/// Fondo sutil “futuro”: malla + glow sin saturar el contenido.
class _FondoFuturista extends StatelessWidget {
  const _FondoFuturista({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF0F4FF), Color(0xFFF8FAFC), Color(0xFFEEF2FF)],
            ),
          ),
        ),
        // Glow superior
        Positioned(
          top: -80,
          right: -60,
          child: IgnorePointer(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.18),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Glow inferior
        Positioned(
          bottom: 40,
          left: -40,
          child: IgnorePointer(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.info.withValues(alpha: 0.12),
                    AppColors.info.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Línea “tech” superior
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.0),
                    AppColors.primary.withValues(alpha: 0.55),
                    AppColors.info.withValues(alpha: 0.45),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
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

    this.compact = false,
  });

  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pad = compact ? 10.0 : 14.0;
    final iconSize = compact ? 18.0 : 22.0;
    final box = compact ? 32.0 : 40.0;

    final child = Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: box,
            height: box,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          SizedBox(width: compact ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 10 : 11,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 14 : 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (!compact && hint.isNotEmpty)
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

    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: child,
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
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.grey400,
          ),
        ],
      ),
    );
  }
}

/// Carrusel tipo panel bancario: rota indicadores con progreso y fade.
class _InsightsCarousel extends ConsumerStatefulWidget {
  const _InsightsCarousel({required this.onNuevaCotizacion});

  final VoidCallback onNuevaCotizacion;

  @override
  ConsumerState<_InsightsCarousel> createState() => _InsightsCarouselState();
}

class _InsightsCarouselState extends ConsumerState<_InsightsCarousel>
    with SingleTickerProviderStateMixin {
  static const _interval = Duration(seconds: 6);

  int _index = 0;
  bool _paused = false;
  List<_InsightSlide> _slides = const [];

  late final AnimationController _progress;


  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: _interval)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted && !_paused) {
          _goNext();
        }
      });
    _progress.forward();
  }

  void _goNext() {
    if (!mounted || _slides.isEmpty) {
      _progress
        ..reset()
        ..forward();
      return;
    }
    setState(() => _index = (_index + 1) % _slides.length);
    _progress
      ..reset()
      ..forward();
  }

  void _goTo(int i) {
    setState(() => _index = i);
    _progress
      ..reset()
      ..forward();
  }

  void _setPaused(bool v) {
    if (_paused == v) return;
    setState(() => _paused = v);
    if (v) {
      _progress.stop();
    } else {
      _progress.forward();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  List<_InsightSlide> _buildSlides(DashboardSnapshot? snapshot) {
    final hoy = snapshot?.hoy;
    final mes = snapshot?.mes;
    final formasPago = snapshot?.porFormaPago.entries.toList() ?? [];
    formasPago.sort((a, b) => b.value.compareTo(a.value));
    final topProducto = snapshot?.topProductos.isNotEmpty == true
        ? snapshot!.topProductos.first
        : null;

    return [
      _InsightSlide(
        icon: Icons.point_of_sale_rounded,
        color: AppColors.primary,
        badge: 'VENTAS · HOY',
        title: 'Ventas de hoy',
        body: hoy == null
            ? 'Resumen de ventas del día.'
            : '${hoy.numFacturas} factura(s) registradas hoy.',
        value: hoy == null ? '—' : formatRd(hoy.ventas),
        footer: hoy == null ? 'Cargando reportes…' : 'Fuente: Reportes · Hoy',
      ),
      _InsightSlide(
        icon: Icons.trending_up_rounded,
        color: AppColors.info,
        badge: 'GANANCIA · HOY',
        title: 'Ganancia estimada',
        body: 'Ventas menos costo de los productos vendidos hoy.',
        value: hoy == null ? '—' : formatRd(hoy.ganancia),
        footer: hoy == null ? 'Cargando reportes…' : 'Fuente: Reportes · Hoy',
      ),
      _InsightSlide(
        icon: Icons.receipt_long_outlined,
        color: AppColors.warning,
        badge: 'TICKET · HOY',
        title: 'Ticket promedio',
        body: 'Promedio vendido por factura registrada hoy.',
        value: hoy == null ? '—' : formatRd(hoy.ticketPromedio),
        footer: hoy == null ? 'Cargando reportes…' : 'Fuente: Reportes · Hoy',
      ),
      _InsightSlide(
        icon: Icons.calendar_month_outlined,
        color: AppColors.success,
        badge: 'VENTAS · MES',
        title: 'Ventas del mes',
        body: mes == null
            ? 'Resumen de ventas del mes en curso.'
            : '${mes.numFacturas} factura(s) registradas este mes.',
        value: mes == null ? '—' : formatRd(mes.ventas),
        footer: mes == null ? 'Cargando reportes…' : 'Fuente: Reportes · Mes',
      ),
      _InsightSlide(
        icon: Icons.payments_outlined,
        color: AppColors.primary,
        badge: 'COBROS · MES',
        title: 'Forma de pago principal',
        body: formasPago.isEmpty
            ? 'Aún no hay pagos reportados este mes.'
            : 'Método con mayor volumen de ventas este mes.',
        value: formasPago.isEmpty ? '—' : formasPago.first.key,
        footer: snapshot == null
            ? 'Cargando reportes…'
            : formasPago.isEmpty
            ? 'Fuente: Reportes · Mes'
            : formatRd(formasPago.first.value),
      ),
      _InsightSlide(
        icon: Icons.star_outline_rounded,
        color: AppColors.warning,
        badge: 'PRODUCTO · MES',
        title: topProducto?.nombre ?? 'Productos destacados',
        body: topProducto == null
            ? 'Los productos más vendidos del mes aparecerán aquí.'
            : 'Producto con mayor venta acumulada este mes.',
        value: topProducto == null ? '—' : formatRd(topProducto.monto),
        footer: snapshot == null
            ? 'Cargando reportes…'
            : topProducto == null
            ? 'Fuente: Reportes · Mes'
            : '${topProducto.cantidad} unidades · Reportes · Mes',
      ),
      const _InsightSlide(
        icon: Icons.bolt_outlined,
        color: AppColors.primary,
        badge: 'ATAJO',
        title: 'Empezar ahora',
        body: 'Genera una cotización y avanza el flujo en minutos.',
        value: 'Venta',
        footer: 'Acción rápida',
        showCta: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(dashboardSnapshotProvider).valueOrNull;
    _slides = _buildSlides(snapshot);
    final s = _slides[_index.clamp(0, _slides.length - 1)];

    return MouseRegion(
      onEnter: (_) => _setPaused(true),
      onExit: (_) => _setPaused(false),
      child: GestureDetector(
        onTapDown: (_) => _setPaused(true),
        onTapUp: (_) => _setPaused(false),
        onTapCancel: () => _setPaused(false),
        child: AppCard(
          accent: true,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra de progreso del ciclo
              AnimatedBuilder(
                animation: _progress,
                builder: (_, __) {
                  return LinearProgressIndicator(
                    value: _paused ? _progress.value : _progress.value,
                    minHeight: 3,
                    backgroundColor: AppColors.grey100,
                    color: s.color,
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: s.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s.badge,
                            style: AppTypography.labelSmall.copyWith(
                              color: s.color,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_index + 1}/${_slides.length}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 380),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, anim) {
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(_index),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: s.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(s.icon, color: s.color, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.title,
                                    style: AppTypography.labelMedium.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.value,
                                    style: AppTypography.h3.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    s.body,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.35,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    s.footer,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: s.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (s.showCta) ...[
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed: widget.onNuevaCotizacion,
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('Nueva cotización'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Puntos clicables
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (i) {
                        final on = i == _index;
                        return GestureDetector(
                          onTap: () => _goTo(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: on ? 18 : 7,
                            height: 7,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: on ? s.color : AppColors.grey300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightSlide {
  const _InsightSlide({
    required this.icon,
    required this.color,
    required this.badge,
    required this.title,
    required this.body,
    required this.value,
    required this.footer,
    this.showCta = false,
  });

  final IconData icon;
  final Color color;
  final String badge;
  final String title;
  final String body;
  final String value;
  final String footer;
  final bool showCta;
}

class _FondoPuntosPainter extends CustomPainter {
  _FondoPuntosPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const step = 18.0;
    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        canvas.drawCircle(
          Offset(x + ((y ~/ step).isEven ? 0.0 : 6.0), y),
          1.1,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FondoPuntosPainter oldDelegate) =>
      oldDelegate.color != color;
}
