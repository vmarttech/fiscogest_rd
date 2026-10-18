import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:fiscogest_rd/features/reportes/domain/kpi_models.dart';
import 'package:fiscogest_rd/features/reportes/presentation/providers/dashboard_providers.dart';
import 'package:fiscogest_rd/features/creditos/presentation/pages/cuentas_cobrar_page.dart'
    show creditoTotalesProvider;
import 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';

final inventoryFilterProvider = StateProvider.autoDispose<String>((ref) => 'all');
/// '7' | '30'
final chartRangeProvider = StateProvider.autoDispose<String>((ref) => '7');

/// Dashboard 100% alineado a dashboard_fiscogest_enterprise.html
class DashboardDesktopProto extends ConsumerWidget {
  const DashboardDesktopProto({super.key});

  void _go(BuildContext context, String ruta) => context.push(ruta);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(dashboardSnapshotProvider).valueOrNull;
    final creditoTot = ref.watch(creditoTotalesProvider).valueOrNull;
    final cajaDash = ref.watch(dashCajaProvider).valueOrNull;
    final ventasLista =
        ref.watch(listaVentasProvider).valueOrNull ?? <Venta>[];
    final productos =
        ref.watch(productoControllerProvider).valueOrNull ?? <Producto>[];
    final sesion = ref.watch(sesionProvider);

    final ventasHoy = snapshot?.hoy.ventas ?? 0.0;
    final deltaVentas = snapshot?.hoy.deltaVentasPct ?? 0.0;
    final porCobrar = creditoTot?.porCobrar ?? 0.0;
    final vencido = creditoTot?.vencido ?? 0.0;
    final numClientes = creditoTot?.clientes ?? 0;
    final cajaAbierta = cajaDash?.abierta ?? false;
    final cajaEfectivo = cajaAbierta ? (cajaDash?.efectivo ?? 0.0) : 0.0;
    final cajaLabel = cajaDash?.label ?? 'Caja cerrada';
    final serie = snapshot?.serie30Dias ?? const <SeriePunto>[];
    final chartRange = ref.watch(chartRangeProvider);
    final serieChart = chartRange == '30'
        ? serie
        : (serie.length >= 7 ? serie.sublist(serie.length - 7) : serie);
    final kpiRango = chartRange == '30' ? snapshot?.mes : snapshot?.semana;
    final ventasRango = kpiRango?.ventas ?? 0.0;
    final facturasRango = kpiRango?.numFacturas ?? 0;
    final ticketRango = kpiRango?.ticketPromedio ?? 0.0;
    final topActividad = ([...ventasLista]
          ..sort((a, b) => b.fecha.compareTo(a.fecha)))
        .take(5)
        .toList();
    final productosInv = ([...productos]
          ..sort((a, b) => (a.stock ?? 0).compareTo(b.stock ?? 0)))
        .take(6)
        .toList();

    final invFilter = ref.watch(inventoryFilterProvider);
    final productosFiltrados = productosInv.where((pr) {
      final s = pr.stock ?? 0;
      final min = pr.stockMinimo ?? 0;
      switch (invFilter) {
        case 'Pagado':
          return s > min;
        case 'Pendiente':
          return s > 0 && s <= min;
        case 'Agotado':
          return s <= 0;
        default:
          return true;
      }
    }).toList();

    final nombre = sesion?.nombre.isNotEmpty == true
        ? sesion!.nombre.split(' ').first
        : 'Administrador';
    final fecha =
        DateFormat("EEEE, d 'de' MMMM yyyy", 'es').format(DateTime.now());

    return ColoredBox(
      color: const Color(0xFFF1F5F9), // slate-100
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ═══ 1. HERO BANNER ═══
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                    Color(0xFF1E3A8A),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.ssid_chart,
                                size: 14, color: Color(0xFF93C5FD)),
                            SizedBox(width: 6),
                            Text(
                              'CENTRO DE CONTROL FISCAL Y FINANCIERO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: Color(0xFF93C5FD),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '¡Hola, $nombre!',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Visión general del rendimiento operacional de tu negocio. '
                          'Monitoriza comprobantes fiscales (e-CF), liquidez en caja '
                          'y comportamiento crediticio en tiempo real.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.75),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 13, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 6),
                            Text(
                              fecha,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 0,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Sistema Operativo',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6EE7B7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      FilledButton.icon(
                        onPressed: () =>
                            _go(context, '/ventas/cotizaciones/nueva'),
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: const Text('Nueva Venta'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _go(context, '/ecfe'),
                        icon: const Icon(Icons.fact_check_outlined, size: 16),
                        label: const Text('Emitir e-CF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.35)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ═══ 2. KPI CARDS (glass white) ═══
            Row(
              children: [
                Expanded(
                  child: _KpiGlass(
                    title: 'VENTAS DEL DÍA',
                    value: formatRd(ventasHoy),
                    badge: ventasHoy <= 0
                        ? 'Sin ventas hoy'
                        : '${deltaVentas >= 0 ? "↑" : "↓"} ${deltaVentas.abs().toStringAsFixed(1)}% vs. día anterior',
                    badgeColor: deltaVentas >= 0
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                    badgeBg: deltaVentas >= 0
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF2F2),
                    icon: Icons.trending_up,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF2563EB),
                    onTap: () => _go(context, '/ventas/historial'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _KpiGlass(
                    title: 'CUENTAS POR COBRAR',
                    value: formatRd(porCobrar),
                    badge: vencido > 0
                        ? '${formatRd(vencido)} vencido'
                        : 'Al día con normativas',
                    badgeColor: vencido > 0
                        ? const Color(0xFFD97706)
                        : const Color(0xFF059669),
                    badgeBg: vencido > 0
                        ? const Color(0xFFFFFBEB)
                        : const Color(0xFFECFDF5),
                    icon: Icons.receipt_long_outlined,
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: const Color(0xFF059669),
                    onTap: () => _go(context, '/creditos/cuentas'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _KpiGlass(
                    title: 'CRÉDITOS PENDIENTES',
                    value: formatRd(porCobrar),
                    badge: numClientes > 0
                        ? '$numClientes cliente(s) con deuda'
                        : 'Sin créditos activos',
                    badgeColor: const Color(0xFFB45309),
                    badgeBg: const Color(0xFFFFFBEB),
                    icon: Icons.schedule,
                    iconBg: const Color(0xFFFFFBEB),
                    iconColor: const Color(0xFFD97706),
                    onTap: () => _go(context, '/creditos'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _KpiGlass(
                    title: 'TOTAL EN CAJA',
                    value: formatRd(cajaEfectivo),
                    badge: cajaLabel,
                    badgeColor: cajaAbierta
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFF64748B),
                    badgeBg: cajaAbierta
                        ? const Color(0xFFF5F3FF)
                        : const Color(0xFFF1F5F9),
                    icon: Icons.account_balance_wallet_outlined,
                    iconBg: cajaAbierta
                        ? const Color(0xFFF5F3FF)
                        : const Color(0xFFF1F5F9),
                    iconColor: cajaAbierta
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFF64748B),
                    onTap: () => _go(context, '/ventas/cobro'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ═══ 3. CHART (8) + QUICK + ACTIVITY (4) ═══
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Chart 8/12
                  Expanded(
                    flex: 8,
                    child: _WhiteCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bar_chart_rounded,
                                  size: 18, color: Color(0xFF2563EB)),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Resumen de Ventas',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      'Comportamiento de ingresos y facturación e-CF',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Material(
                                      color: chartRange == '7'
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      elevation: chartRange == '7' ? 1 : 0,
                                      shadowColor: const Color(0x14000000),
                                      child: InkWell(
                                        onTap: () => ref
                                            .read(chartRangeProvider.notifier)
                                            .state = '7',
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          child: Text(
                                            'Últimos 7 días',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: chartRange == '7'
                                                  ? const Color(0xFF2563EB)
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Material(
                                      color: chartRange == '30'
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      elevation: chartRange == '30' ? 1 : 0,
                                      shadowColor: const Color(0x14000000),
                                      child: InkWell(
                                        onTap: () => ref
                                            .read(chartRangeProvider.notifier)
                                            .state = '30',
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          child: Text(
                                            '30 días',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: chartRange == '30'
                                                  ? const Color(0xFF2563EB)
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Gráfico a altura original
                          SizedBox(
                            height: 220,
                            child: _EnterpriseChart(puntos: serieChart),
                          ),
                          // Empuja las métricas al pie de la tarjeta
                          const Spacer(),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _FootMetric(
                                  label: 'VENTAS REGISTRADAS',
                                  value: formatRd(ventasRango),
                                ),
                              ),
                              Expanded(
                                child: _FootMetric(
                                  label: 'FACTURAS EMITIDAS',
                                  value: '$facturasRango',
                                ),
                              ),
                              Expanded(
                                child: _FootMetric(
                                  label: 'TICKET PROMEDIO',
                                  value: formatRd(ticketRango),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Quick + Activity 4/12
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        _WhiteCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.bolt,
                                      size: 16, color: Color(0xFFF59E0B)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Acciones Rápidas',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _QuickTile(
                                      icon: Icons.shopping_bag_outlined,
                                      bg: const Color(0xFFDBEAFE),
                                      fg: const Color(0xFF2563EB),
                                      title: 'Nueva venta',
                                      sub: 'Punto de venta',
                                      onTap: () => _go(context,
                                          '/ventas/cotizaciones/nueva'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _QuickTile(
                                      icon: Icons.badge_outlined,
                                      bg: const Color(0xFFF3E8FF),
                                      fg: const Color(0xFF9333EA),
                                      title: 'Emitir e-CF',
                                      sub: 'Factura electrónica',
                                      onTap: () => _go(context, '/ecfe'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _QuickTile(
                                      icon: Icons.credit_card,
                                      bg: const Color(0xFFFEF3C7),
                                      fg: const Color(0xFFD97706),
                                      title: 'Nuevo crédito',
                                      sub: 'Crédito a cliente',
                                      onTap: () =>
                                          _go(context, '/creditos'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _QuickTile(
                                      icon: Icons.person_add_outlined,
                                      bg: const Color(0xFFD1FAE5),
                                      fg: const Color(0xFF059669),
                                      title: 'Nuevo cliente',
                                      sub: 'Registrar RNC',
                                      onTap: () =>
                                          _go(context, '/clientes'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _WhiteCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.history,
                                        size: 16,
                                        color: Color(0xFF2563EB)),
                                    const SizedBox(width: 6),
                                    const Expanded(
                                      child: Text(
                                        'Actividad Reciente',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () =>
                                          _go(context, '/ventas'),
                                      child: const Text(
                                        'Ver todas →',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (topActividad.isEmpty)
                                  const Text('Sin actividad reciente',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF94A3B8)))
                                else
                                  ...topActividad.map((v) {
                                    final forma =
                                        v.formaPago.toLowerCase();
                                    final esCredito = v.esCredito ||
                                        forma.contains('credito') ||
                                        forma.contains('crédito');
                                    final icon = esCredito
                                        ? Icons.credit_card
                                        : Icons.check;
                                    final bg = esCredito
                                        ? const Color(0xFFFEF3C7)
                                        : const Color(0xFFD1FAE5);
                                    final fg = esCredito
                                        ? const Color(0xFFD97706)
                                        : const Color(0xFF059669);
                                    final hora =
                                        '${v.fecha.hour.toString().padLeft(2, '0')}:${v.fecha.minute.toString().padLeft(2, '0')}';
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 8),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: bg,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(icon,
                                                size: 14, color: fg),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                Text(
                                                  esCredito
                                                      ? 'Crédito Aprobado'
                                                      : 'Venta realizada',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    color: Color(
                                                        0xFF0F172A),
                                                  ),
                                                ),
                                                Text(
                                                  '${v.numeroFactura ?? v.numero} · ${v.nombreCliente ?? "Cliente"}',
                                                  maxLines: 1,
                                                  overflow: TextOverflow
                                                      .ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Color(
                                                        0xFF94A3B8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                formatRd(v.montoTotal),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w800,
                                                  color:
                                                      Color(0xFF0F172A),
                                                ),
                                              ),
                                              Text(
                                                hora,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color(
                                                      0xFF94A3B8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ═══ 4. INVENTARIO TABLE + RESUMEN FINANCIERO ═══
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 8,
                    child: _WhiteCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  size: 18, color: Color(0xFF2563EB)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Estado del Inventario y Movimientos',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      'Artículos en almacén y estatus comercial',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Filtros HTML
                          Row(
                            children: [
                              _FilterChip(
                                label: 'Todos',
                                selected: invFilter == 'all',
                                onTap: () => ref.read(inventoryFilterProvider.notifier).state = 'all',
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Pagados',
                                selected: invFilter == 'Pagado',
                                onTap: () => ref.read(inventoryFilterProvider.notifier).state = 'Pagado',
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Pendientes',
                                selected: invFilter == 'Pendiente',
                                onTap: () => ref.read(inventoryFilterProvider.notifier).state = 'Pendiente',
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Agotados',
                                selected: invFilter == 'Agotado',
                                onTap: () => ref.read(inventoryFilterProvider.notifier).state = 'Agotado',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Header 6 columnas HTML
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 4, child: Text('CLIENTE / PRODUCTO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.4))),
                                Expanded(flex: 2, child: Text('NIF / REFERENCIA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)))),
                                Expanded(flex: 2, child: Text('MONTO / VALOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)))),
                                Expanded(flex: 2, child: Text('ESTADO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)))),
                                Expanded(flex: 2, child: Text('STOCK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)))),
                                SizedBox(width: 64, child: Text('ACCIÓN', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)))),
                              ],
                            ),
                          ),
                          if (productosFiltrados.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Sin productos',
                                  style: TextStyle(
                                      color: Color(0xFF94A3B8))),
                            )
                          else
                            ...productosFiltrados.map((pr) {
                              final s = pr.stock ?? 0;
                              final min = pr.stockMinimo ?? 0;
                              late String badge;
                              late Color bc, bb;
                              late String accion;
                              if (s <= 0) {
                                badge = 'Agotado';
                                bc = const Color(0xFF991B1B);
                                bb = const Color(0xFFFEE2E2);
                                accion = 'Reponer';
                              } else if (s <= min) {
                                badge = 'Stock bajo';
                                bc = const Color(0xFFB45309);
                                bb = const Color(0xFFFEF3C7);
                                accion = 'Ver';
                              } else {
                                badge = 'Disponible';
                                bc = const Color(0xFF065F46);
                                bb = const Color(0xFFD1FAE5);
                                accion = 'Ver';
                              }
                              final precio = pr.precioVenta;
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: Text(
                                          pr.nombre,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: Text(
                                          pr.codigo,
                                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF64748B)),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: Text(
                                          formatRd(precio),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(color: bb, borderRadius: BorderRadius.circular(20)),
                                            child: Text(badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: bc)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Text(
                                          s <= 0
                                              ? '0 unidades'
                                              : (s <= min ? '${s.toStringAsFixed(0)} u (bajo)' : '${s.toStringAsFixed(0)} unidades'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: s <= 0
                                                ? const Color(0xFFDC2626)
                                                : (s <= min ? const Color(0xFFD97706) : const Color(0xFF059669)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 64,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () => _go(context, '/inventario'),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Text(accion, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  _go(context, '/inventario'),
                              child: const Text('Ver inventario →'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _WhiteCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.pie_chart_outline,
                                  size: 18, color: Color(0xFF9333EA)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Resumen Financiero',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Text(
                                'HOY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _FinRow('Ventas brutas', formatRd(ventasHoy),
                              const Color(0xFF0F172A)),
                          const SizedBox(height: 8),
                          _FinRow(
                              'Créditos diferidos',
                              formatRd(porCobrar),
                              const Color(0xFFD97706)),
                          const SizedBox(height: 8),
                          _FinRow(
                              'Gastos operacionales',
                              formatRd(snapshot?.hoy.gastos ?? 0),
                              const Color(0xFFDC2626)),
                          const Spacer(),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 24,
                            ),
                            constraints: const BoxConstraints(minHeight: 96),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF0F172A),
                                  Color(0xFF1E293B),
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'BALANCE NETO ESTIMADO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  formatRd(cajaEfectivo),
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF34D399),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

// ─── Providers ───────────────────────────────────────────────────────────

/// Estado de caja del dashboard (invalidar al abrir/cerrar turno).
final dashCajaProvider = FutureProvider.autoDispose<
    ({bool abierta, double efectivo, String label})>((ref) async {
  final repo = ref.watch(cajaRepositoryProvider);
  final sesion = await repo.obtenerSesionAbierta();
  if (sesion == null || !sesion.estaAbierta) {
    return (abierta: false, efectivo: 0.0, label: 'Caja cerrada');
  }
  try {
    final resumen = await repo.obtenerResumenSesion(sesion.id);
    return (
      abierta: true,
      efectivo: resumen.efectivoEsperado,
      label: 'Sesión #${sesion.id} • Abierta',
    );
  } catch (_) {
    return (
      abierta: true,
      efectivo: sesion.fondoInicial,
      label: 'Sesión #${sesion.id} • Abierta',
    );
  }
});


// ─── UI atoms ────────────────────────────────────────────────────────────

class _KpiGlass extends StatelessWidget {
  const _KpiGlass({
    required this.title,
    required this.value,
    required this.badge,
    required this.badgeColor,
    required this.badgeBg,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.onTap,
  });
  final String title, value, badge;
  final Color badgeColor, badgeBg, iconBg, iconColor;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: badgeColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
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

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.title,
    required this.sub,
    required this.onTap,
  });
  final IconData icon;
  final Color bg, fg;
  final String title, sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: fg),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FootMetric extends StatelessWidget {
  const _FootMetric({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _FinRow extends StatelessWidget {
  const _FinRow(this.label, this.value, this.valueColor);
  final String label, value;
  final Color valueColor;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF64748B))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: valueColor)),
        ],
      ),
    );
  }
}

class _EnterpriseChart extends StatelessWidget {
  const _EnterpriseChart({required this.puntos});
  final List<SeriePunto> puntos;

  /// Etiquetas del eje Y compactas (evita corte vertical).
  static String _ejeY(double v) {
    if (v >= 1000000) return 'RD\$${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'RD\$${(v / 1000).toStringAsFixed(1)}k';
    return 'RD\$${v.toStringAsFixed(0)}';
  }

  /// Solo ~6 etiquetas en X (evita overflow con 30 días).
  List<({int index, String label})> _labelsX() {
    final n = puntos.length;
    if (n == 0) return const [];
    final maxLabels = n <= 8 ? n : 6;
    if (n <= maxLabels) {
      return [
        for (var i = 0; i < n; i++)
          (index: i, label: _corto(puntos[i].label)),
      ];
    }
    final out = <({int index, String label})>[];
    for (var k = 0; k < maxLabels; k++) {
      final i = ((n - 1) * k / (maxLabels - 1)).round().clamp(0, n - 1);
      if (out.isEmpty || out.last.index != i) {
        out.add((index: i, label: _corto(puntos[i].label)));
      }
    }
    return out;
  }

  static String _corto(String raw) {
    final s = raw.trim();
    if (s.length <= 6) return s;
    // dd/MM o similar
    final parts = s.split(RegExp(r'[/\-\s]'));
    if (parts.length >= 2) {
      return '${parts[0]}/${parts[1]}';
    }
    return s.substring(0, 6);
  }

  @override
  Widget build(BuildContext context) {
    if (puntos.isEmpty) {
      return const Center(
        child: Text('Sin datos', style: TextStyle(color: Color(0xFF94A3B8))),
      );
    }
    final maxV =
        puntos.map((p) => p.valor).fold<double>(0, (a, b) => b > a ? b : a);
    final scaleMax =
        maxV <= 0 ? 1000.0 : (maxV * 1.15).clamp(100.0, double.infinity);
    final labelsX = _labelsX();

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 220.0;
        final chartH = (h - 22).clamp(120.0, h);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Eje Y — ancho flexible, texto compacto, sin corte
            SizedBox(
              width: 58,
              height: chartH,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 4; i >= 0; i--)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _ejeY(scaleMax * i / 4),
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.0,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: chartH,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _EntChartPainter(puntos, scaleMax),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Eje X — solo labels muestreados, sin overflow
                  SizedBox(
                    height: 16,
                    child: LayoutBuilder(
                      builder: (context, c) {
                        return Stack(
                          children: [
                            for (final item in labelsX)
                              Positioned(
                                left: puntos.length <= 1
                                    ? c.maxWidth / 2 - 16
                                    : (item.index / (puntos.length - 1)) *
                                            c.maxWidth -
                                        16,
                                width: 32,
                                child: Text(
                                  item.label,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EntChartPainter extends CustomPainter {
  _EntChartPainter(this.puntos, this.scaleMax);
  final List<SeriePunto> puntos;
  final double scaleMax;

  @override
  void paint(Canvas canvas, Size size) {
    if (puntos.isEmpty || scaleMax <= 0) return;
    final n = puntos.length;
    final h = size.height;
    final w = size.width;

    final grid = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = h * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }

    final pts = <Offset>[];
    for (var i = 0; i < n; i++) {
      final x = n == 1 ? w / 2 : i * w / (n - 1);
      final y = h - (puntos[i].valor / scaleMax) * h;
      pts.add(Offset(x, y.clamp(2.0, h - 2.0)));
    }

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    final area = Path.from(path)
      ..lineTo(pts.last.dx, h)
      ..lineTo(pts.first.dx, h)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2563EB).withValues(alpha: 0.12),
            const Color(0xFF2563EB).withValues(alpha: 0.01),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF2563EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Puntos solo si caben (máx ~15)
    final step = n > 15 ? (n / 12).ceil() : 1;
    for (var i = 0; i < n; i += step) {
      final o = pts[i];
      canvas.drawCircle(o, 4, Paint()..color = Colors.white);
      canvas.drawCircle(
        o,
        4,
        Paint()
          ..color = const Color(0xFF2563EB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawCircle(o, 2.5, Paint()..color = const Color(0xFF2563EB));
    }
  }

  @override
  bool shouldRepaint(covariant _EntChartPainter old) =>
      old.puntos != puntos || old.scaleMax != scaleMax;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFDBEAFE) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}
