
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/presentation/widgets/shell_drawer_scope.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/reportes/presentation/providers/dashboard_providers.dart';
import 'package:fiscogest_rd/features/notificaciones/presentation/campana_notificaciones.dart';
import 'package:fiscogest_rd/features/creditos/presentation/pages/cuentas_cobrar_page.dart'
    show creditoTotalesProvider;

/// Home móvil — capas sin solapar:
/// KPI = consultar | Acciones = crear | Módulos = áreas | Bottom = atajos únicos
class HomeMobilePage extends ConsumerWidget {
  const HomeMobilePage({super.key});

  static const Color _teal = Color(0xFF00796B);
  static const Color _tealSoft = Color(0xFFE0F2F1);
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _text = Color(0xFF1E293B);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _dangerSoft = Color(0xFFFEE2E2);
  static const Color _warning = Color(0xFFD97706);
  static const Color _warningSoft = Color(0xFFFEF3C7);

  static const List<BoxShadow> _cardShadow = [
    BoxShadow(color: Color(0x1A0F172A), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0D00796B), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> _cardShadowSoft = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 8, offset: Offset(0, 3)),
  ];

  static final _rd = NumberFormat.currency(
    locale: 'es_DO',
    symbol: r'RD$',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(configuracionControllerProvider).valueOrNull;
    final n1 = cfg?.nombreComercial.trim() ?? '';
    final n2 = cfg?.razonSocial.trim() ?? '';
    final negocio =
        n1.isNotEmpty ? n1 : (n2.isNotEmpty ? n2 : 'Mi negocio');
    final direccionStr = (cfg?.direccion ?? '').trim();
final dash = ref.watch(dashboardSnapshotProvider);
    final ventasHoy = dash.when(
      data: (s) => _rd.format(s.hoy.ventas),
      loading: () => '…',
      error: (_, __) => _rd.format(0),
    );

    final productos =
        ref.watch(productoControllerProvider).valueOrNull ?? const [];
    final bajos = productos.where((p) {
      final stock = p.stock ?? 0;
      return p.activo && stock <= (p.stockMinimo ?? 10);
    }).length;
    final stockLabel = '$bajos ítem${bajos == 1 ? '' : 's'}';

    final totalesCxC = ref.watch(creditoTotalesProvider);
    final porCobrarStr = totalesCxC.when(
      data: (tot) => _rd.format(tot.porCobrar),
      loading: () => '…',
      error: (_, __) => '—',
    );

    void go(String ruta) {
      if (ruta.isEmpty) return;
      context.push(ruta);
    }

    return Scaffold(
      backgroundColor: _bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE0F2F1),
              Color(0xFFF8FAFC),
              Color(0xFFF1F5F9),
            ],
            stops: [0.0, 0.22, 1.0],
          ),
        ),
        child: Column(
          children: [
            _Header(
              negocio: negocio,
              direccion: direccionStr,
              fechaSub: _fechaHoy(),
              onMenu: () => ShellDrawerScope.open(context),
              trailing: Theme(
                data: Theme.of(context).copyWith(
                  iconTheme:
                      const IconThemeData(color: Colors.white, size: 22),
                ),
                child: const CampanaNotificaciones(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  const _SectionTitle('Hoy a simple vista'),
                  const SizedBox(height: 10),
                  _KpiGrid(
                    ventasHoy: ventasHoy,
                    porCobrar: porCobrarStr,
                    porPagar: '—',
                    stockBajo: stockLabel,
                    onVentas: null,
                    onPorCobrar: () => go('/creditos/cuentas'),
                    onPorPagar: () => go('/compras/cuentas-pagar'),
                    onStock: () => go('/inventario?filtro=bajo'),
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle('Acciones rápidas'),
                  const SizedBox(height: 10),
                  _AccionesRapidas(
                    onNuevaVenta: () => go('/ventas/cotizaciones/nueva'),
                    onCompra: () => go('/compras/registrar'),
                    onGasto: () => go('/gastos'),
                    onCliente: () => go('/clientes/nuevo'),
                    onProducto: () => go('/productos/nuevo'),
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle('Módulos'),
                  const SizedBox(height: 10),
                  _ModulosGrid(
                    onTap: (id) {
                      switch (id) {
                        case 'facturacion':
                          go('/sales');
                        case 'credito':
                          go('/creditos');
                        case 'compras':
                          go('/compras');
                        case 'gastos':
                          go('/gastos');
                        case 'inventario':
                          go('/inventario');
                        case 'clientes':
                          go('/clientes');
                        case 'proveedores':
                          go('/proveedores');
                        case 'fiados':
                          go('/ventas/fios');
                        case 'reportes':
                          go('/reports');
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                          child: _SectionTitle('Actividad reciente')),
                      GestureDetector(
                        onTap: () => go('/reports'),
                        child: const Text(
                          'Ver todo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ActividadReciente(
                    onCompra: () => go('/compras/lista'),
                    onCxc: () => go('/creditos/cuentas'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: 0,
        onTap: (i) {
          switch (i) {
            case 0:
              break;
            case 1:
              go('/ventas/historial');
            case 3:
              go('/configuracion');
          }
        },
        onFab: () => _showFab(context),
      ),
    );
  }

  static String _fechaHoy() {
    const d = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves',
      'Viernes', 'Sábado', 'Domingo',
    ];
    const m = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final n = DateTime.now();
    return '${d[n.weekday - 1]}, ${n.day} ${m[n.month - 1]}';
  }

  void _showFab(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nueva acción',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _text,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.add_shopping_cart, color: _teal),
                title: const Text(
                  'Nueva venta',
                  style: TextStyle(fontWeight: FontWeight.w700, color: _text),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/ventas/cotizaciones/nueva');
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.add_business_outlined, color: _teal),
                title: const Text(
                  'Nueva compra',
                  style: TextStyle(fontWeight: FontWeight.w700, color: _text),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/compras/registrar');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: HomeMobilePage._text,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.negocio,
    required this.fechaSub,
    required this.trailing,
    required this.onMenu,
    this.direccion = '',
  });

  final String negocio;
  final String direccion;
  final String fechaSub;
  final Widget trailing;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeMobilePage._teal,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00796B),
              Color(0xFF00695C),
              Color(0xFF004D40),
            ],
          ),
        ),
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + 4,
          left: 2,
          right: 4,
          bottom: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Menú',
                  onPressed: onMenu,
                  icon: const Icon(Icons.menu_rounded,
                      color: Colors.white, size: 26),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        negocio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                          height: 1.15,
                        ),
                      ),
                      if (direccion.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          direccion,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.88),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing,
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.9)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fechaSub,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6EE7B7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sistema OK',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({
    required this.ventasHoy,
    required this.porCobrar,
    required this.porPagar,
    required this.stockBajo,
    this.onVentas,
    this.onPorCobrar,
    this.onPorPagar,
    this.onStock,
  });

  final String ventasHoy, porCobrar, porPagar, stockBajo;
  final VoidCallback? onVentas, onPorCobrar, onPorPagar, onStock;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _KpiCard(
          icon: Icons.show_chart,
          iconBg: HomeMobilePage._tealSoft,
          iconColor: HomeMobilePage._teal,
          label: 'Ventas hoy',
          value: ventasHoy,
          onTap: onVentas,
        ),
        _KpiCard(
          icon: Icons.warning_amber_rounded,
          iconBg: HomeMobilePage._warningSoft,
          iconColor: HomeMobilePage._warning,
          label: 'Por cobrar',
          value: porCobrar,
          onTap: onPorCobrar,
        ),
        _KpiCard(
          icon: Icons.payments_outlined,
          iconBg: HomeMobilePage._tealSoft,
          iconColor: HomeMobilePage._teal,
          label: 'Por pagar',
          value: porPagar,
          onTap: onPorPagar,
        ),
        _KpiCard(
          icon: Icons.inventory_2_outlined,
          iconBg: HomeMobilePage._dangerSoft,
          iconColor: HomeMobilePage._danger,
          label: 'Stock bajo',
          value: stockBajo,
          valueColor: HomeMobilePage._danger,
          onTap: onStock,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg, iconColor;
  final String label, value;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HomeMobilePage._border),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF0FDFA)],
            ),
            boxShadow: HomeMobilePage._cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration:
                        BoxDecoration(color: iconBg, shape: BoxShape.circle),
                    child: Icon(icon, size: 16, color: iconColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: HomeMobilePage._muted,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? HomeMobilePage._text,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccionesRapidas extends StatelessWidget {
  const _AccionesRapidas({
    required this.onNuevaVenta,
    required this.onCompra,
    required this.onGasto,
    required this.onCliente,
    required this.onProducto,
  });

  final VoidCallback onNuevaVenta, onCompra, onGasto, onCliente, onProducto;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _PrimaryBtn(
                icon: Icons.add_shopping_cart,
                label: 'Nueva venta',
                onTap: onNuevaVenta,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PrimaryBtn(
                icon: Icons.add_business_outlined,
                label: 'Compra',
                onTap: onCompra,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _OutlineBtn(
                icon: Icons.money_off_csred_outlined,
                label: 'Gasto',
                onTap: onGasto,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OutlineBtn(
                icon: Icons.person_add_alt_1_outlined,
                label: 'Cliente',
                onTap: onCliente,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OutlineBtn(
                icon: Icons.add_box_outlined,
                label: 'Producto',
                onTap: onProducto,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeMobilePage._teal,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      shadowColor: const Color(0x4000796B),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: HomeMobilePage._teal, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: HomeMobilePage._teal),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: HomeMobilePage._teal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModulosGrid extends StatelessWidget {
  const _ModulosGrid({required this.onTap});
  final void Function(String id) onTap;

  static const _items = <(String, IconData, String)>[
    ('facturacion', Icons.description_outlined, 'Facturación'),
    ('credito', Icons.credit_score_outlined, 'Crédito'),
    ('compras', Icons.shopping_bag_outlined, 'Compras'),
    ('gastos', Icons.pie_chart_outline, 'Gastos'),
    ('inventario', Icons.warehouse_outlined, 'Inventario'),
    ('clientes', Icons.people_outline, 'Clientes'),
    ('proveedores', Icons.local_shipping_outlined, 'Proveedores'),
    ('fiados', Icons.handshake_outlined, 'Fiados'),
    ('reportes', Icons.insights_outlined, 'Reportes'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (_, i) {
        final (id, icon, label) = _items[i];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => onTap(id),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: HomeMobilePage._border),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFF8FFFE)],
                ),
                boxShadow: HomeMobilePage._cardShadowSoft,
              ),
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 26, color: HomeMobilePage._teal),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: HomeMobilePage._text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActividadReciente extends StatelessWidget {
  const _ActividadReciente({
    required this.onCompra,
    required this.onCxc,
  });

  final VoidCallback onCompra, onCxc;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.local_mall_outlined,
        const Color(0xFFDBEAFE),
        const Color(0xFF2563EB),
        'Compras',
        'Listado de compras',
        onCompra,
      ),
      (
        Icons.schedule,
        HomeMobilePage._warningSoft,
        HomeMobilePage._warning,
        'Cuentas por cobrar',
        'Cobros pendientes',
        onCxc,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HomeMobilePage._border),
        boxShadow: HomeMobilePage._cardShadow,
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: HomeMobilePage._border),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: items[i].$6,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: items[i].$2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(items[i].$1, size: 18, color: items[i].$3),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              items[i].$4,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: HomeMobilePage._text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              items[i].$5,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: HomeMobilePage._muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.onFab,
  });

  final int currentIndex;
  final void Function(int) onTap;
  final VoidCallback onFab;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: HomeMobilePage._border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _item(0, Icons.home_outlined, Icons.home, 'Inicio'),
              _item(1, Icons.history, Icons.history, 'Ventas'),
              Expanded(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -12),
                    child: Material(
                      color: HomeMobilePage._teal,
                      shape: const CircleBorder(),
                      elevation: 4,
                      shadowColor: const Color(0x5900796B),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onFab,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: HomeMobilePage._bg, width: 4),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _item(3, Icons.settings_outlined, Icons.settings, 'Más'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int index, IconData icon, IconData active, String label) {
    final on = currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              on ? active : icon,
              size: 22,
              color: on ? HomeMobilePage._teal : HomeMobilePage._muted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: on ? HomeMobilePage._teal : HomeMobilePage._muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Menú hamburguesa — accesos del home móvil.
