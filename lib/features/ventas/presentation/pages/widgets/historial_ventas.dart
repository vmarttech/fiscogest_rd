import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/core/i18n/servicio_idioma.dart';

/// Historial de ventas — en PC alineado al Dashboard; en móvil vista compacta.
class HistorialVentas extends ConsumerStatefulWidget {
  const HistorialVentas({super.key, this.standalone = false});

  /// true cuando se monta en /ventas/historial (fuera del contenedor).
  final bool standalone;

  @override
  ConsumerState<HistorialVentas> createState() => _HistorialVentasState();
}

class _HistorialVentasState extends ConsumerState<HistorialVentas> {
  final _busqueda = TextEditingController();
  String _filtro = 'todos'; // todos | venta | cotizacion | apartado

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  String _fecha(DateTime f) => DateFormat('dd/MM/yyyy · HH:mm').format(f);
  String _monto(double v) => formatRd(v);

  String _tipo(Venta v) {
    if (_esCotizacion(v)) return 'Cotización';
    if (_esApartado(v)) return 'Apartado';
    return 'Venta';
  }

  Color _colorTipo(Venta v) {
    if (_esCotizacion(v)) return AppColors.info;
    if (_esApartado(v)) return AppColors.warning;
    return AppColors.success;
  }

  bool _esCotizacion(Venta v) {
    final e = v.estadoDocumento.name.toLowerCase();
    return e == 'cotizado' || e == 'aprobado';
  }

  bool _esApartado(Venta v) {
    final e = v.estadoDocumento.name.toLowerCase();
    return e == 'apartado' || v.numero.toUpperCase().startsWith('A');
  }

  bool _esVenta(Venta v) {
    // Facturada / crédito / pagada — no cotización ni apartado
    return !_esCotizacion(v) && !_esApartado(v);
  }

  List<Venta> _filtrar(List<Venta> ventas) {
    final q = _busqueda.text.trim().toLowerCase();
    return ventas.where((v) {
      if (_filtro == 'venta' && !_esVenta(v)) return false;
      if (_filtro == 'cotizacion' && !_esCotizacion(v)) return false;
      if (_filtro == 'apartado' && !_esApartado(v)) return false;
      if (q.isEmpty) return true;
      final cli = (v.nombreCliente ?? '').toLowerCase();
      final ncf = (v.numeroFactura ?? '').toLowerCase();
      return v.numero.toLowerCase().contains(q) ||
          cli.contains(q) ||
          ncf.contains(q);
    }).toList();
  }

  Map<String, num> _kpis(List<Venta> ventas) {
    final ahora = DateTime.now();
    final ini = DateTime(ahora.year, ahora.month, ahora.day);
    final fin = ini.add(const Duration(days: 1));
    var ventasHoy = 0;
    var montoHoy = 0.0;
    var cotiz = 0;
    for (final v in ventas) {
      if (_esCotizacion(v)) {
        cotiz++;
        continue;
      }
      if (_esApartado(v)) continue;
      final f = v.fecha;
      if (!f.isBefore(ini) && f.isBefore(fin)) {
        ventasHoy++;
        montoHoy += v.total;
      }
    }
    return {
      'ventasHoy': ventasHoy,
      'montoHoy': montoHoy,
      'cotizaciones': cotiz,
      'total': ventas.length,
    };
  }

  Future<void> _abrirDetalle(Venta v) async {
    Venta venta = v;
    if (v.id != null) {
      try {
        final Venta? full = await ref
            .read(ventasRepositoryProvider)
            .obtenerVentaPorId(v.id!);
        if (full != null) venta = full;
      } catch (_) {}
    }
    if (!mounted) return;

    if (widget.standalone) {
      final q = venta.id != null ? '?id=${venta.id}' : '';
      await context.push('/ventas/historial/detalle$q', extra: venta);
      return;
    }

    ref
        .read(ventaCargadaDesdeHistorialProvider.notifier)
        .establecerVenta(venta);
    ref
        .read(ventasNavegacionProvider.notifier)
        .cambiarVista(VistaActual.detalle);
  }

  Widget _tarjetaVenta(Venta v, {required bool desktop}) {
    final color = _colorTipo(v);
    final etiqueta = _tipo(v);
    final cliente = (v.nombreCliente ?? '').trim().isEmpty
        ? 'Consumidor final'
        : v.nombreCliente!.trim();
    final ncf = (v.numeroFactura ?? '').trim();

    if (!desktop) {
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _abrirDetalle(v),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              v.numero,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _badgeVenta(etiqueta, color),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fecha(v.fecha),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _monto(v.total),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _abrirDetalle(v),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        v.numero,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    _badgeVenta(etiqueta, color),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cliente,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _fecha(v.fecha),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (ncf.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'NCF: $ncf',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _monto(v.total),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ver detalle',
                      onPressed: () => _abrirDetalle(v),
                      icon: Icon(
                        Icons.open_in_new,
                        size: 19,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 36,
                      ),
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

  Widget _badgeVenta(String etiqueta, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      etiqueta,
      style: TextStyle(
        color: color,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final desktop = AppBreakpoints.isDesktop(context);
    final lista = ref.watch(listaVentasProvider);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: desktop ? 1100 : 960),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            desktop ? 24 : 16,
            desktop ? 16 : 8,
            desktop ? 24 : 16,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Cabecera (estilo Dashboard / Facturación) ──
              if (desktop) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Historial de ventas',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Consulta, reabre e imprime operaciones registradas.',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          ref
                              .read(ventasNavegacionProvider.notifier)
                              .cambiarVista(VistaActual.inicio);
                        }
                      },
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: Text(ServicioIdioma.t(context, 'Volver')),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ] else if (!widget.standalone) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Historial de ventas',
                          style: AppTypography.h4.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => ref
                            .read(ventasNavegacionProvider.notifier)
                            .cambiarVista(VistaActual.inicio),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: Text(ServicioIdioma.t(context, 'Volver')),
                      ),
                    ],
                  ),
                ),
              ],

              Expanded(
                child: lista.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      'Error: $e',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                  data: (ventas) {
                    // Toda la lista; el chip/filtro decide venta vs cotización por estado
                    final kpis = _kpis(ventas);
                    final filtradas = _filtrar(ventas);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // KPIs solo PC
                        if (desktop) ...[
                          Row(
                            children: [
                              Expanded(
                                child: _KpiCard(
                                  icon: Icons.point_of_sale_outlined,
                                  label: 'VENTAS HOY',
                                  value: '${kpis['ventasHoy']}',
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _KpiCard(
                                  icon: Icons.payments_outlined,
                                  label: 'MONTO HOY',
                                  value: _monto(
                                    (kpis['montoHoy'] as num).toDouble(),
                                  ),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _KpiCard(
                                  icon: Icons.request_quote_outlined,
                                  label: 'COTIZACIONES',
                                  value: '${kpis['cotizaciones']}',
                                  color: AppColors.info,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _KpiCard(
                                  icon: Icons.receipt_long_outlined,
                                  label: 'TOTAL REGISTROS',
                                  value: '${kpis['total']}',
                                  color: const Color(0xFF7C3AED),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Buscador + filtros
                        if (desktop)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _busqueda,
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Buscar por número, cliente o NCF…',
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        size: 20,
                                      ),
                                      isDense: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ...[
                                  ('todos', 'Todos'),
                                  ('venta', 'Ventas'),
                                  ('cotizacion', 'Cotiz.'),
                                  ('apartado', 'Apart.'),
                                ].map((e) {
                                  final sel = _filtro == e.$1;
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: FilterChip(
                                      label: Text(e.$2),
                                      selected: sel,
                                      onSelected: (_) => setState(() {
                                        _filtro = e.$1;
                                      }),
                                      selectedColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.15),
                                      checkmarkColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      labelStyle: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        color: sel
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        if (desktop) const SizedBox(height: 12),

                        Expanded(
                          child: filtradas.isEmpty
                              ? Center(
                                  child: Text(
                                    ventas.isEmpty
                                        ? 'No hay registros'
                                        : 'Sin resultados para el filtro',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final columnas =
                                        desktop && constraints.maxWidth >= 820
                                        ? 2
                                        : 1;
                                    return GridView.builder(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      itemCount: filtradas.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: columnas,
                                            crossAxisSpacing: columnas == 2
                                                ? 14
                                                : 0,
                                            mainAxisSpacing: desktop ? 12 : 8,
                                            mainAxisExtent: desktop ? 194 : 82,
                                          ),
                                      itemBuilder: (ctx, i) => _tarjetaVenta(
                                        filtradas[i],
                                        desktop: desktop,
                                      ),
                                    );
                                  },
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
      ),
    );
  }
}

/// KPI del mismo lenguaje visual que Dashboard / Facturación.
class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
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
