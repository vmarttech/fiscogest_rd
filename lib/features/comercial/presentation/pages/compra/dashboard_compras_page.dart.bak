import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/compra/dashboard_compras_providers.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/cuentas_pagar/lista_cuentas_pagar_page.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

class DashboardComprasPage extends ConsumerStatefulWidget {
  const DashboardComprasPage({super.key});
  static const String routeName = 'dashboard-compras';

  @override
  ConsumerState<DashboardComprasPage> createState() =>
      _DashboardComprasPageState();
}

class _DashboardComprasPageState extends ConsumerState<DashboardComprasPage> {
  String _filtroTexto = '';
  /// todos | pagada | credito | pendiente | vencida
  String _filtroEstado = 'todos';
  ActividadRecienteItem? _seleccionada;
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kpisAsync = ref.watch(dashboardComprasKpisProvider);
    final actividadAsync = ref.watch(actividadRecienteComprasProvider);
    final isMobile = AppBreakpoints.isMobile(context);
    final alertas = kpisAsync.maybeWhen(
      data: (k) => k.vencido > 0 ? 1 : 0,
      orElse: () => 0,
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f12): () =>
            context.push('/compras/registrar'),
        const SingleActivator(LogicalKeyboardKey.f2): () =>
            context.goNamed(ListaCuentasPagarPage.routeName),
        const SingleActivator(LogicalKeyboardKey.f3): () =>
            context.goNamed(ListaCuentasPagarPage.routeName),
      },
      child: Focus(
        autofocus: true,
        child: AppScaffold(
          title: isMobile ? 'COMPRAS' : null,
          showAppBar: isMobile,
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(dashboardComprasKpisProvider);
              ref.invalidate(actividadRecienteComprasProvider);
              setState(() => _seleccionada = null);
            },
            child: isMobile
                ? _buildMobile(kpisAsync, actividadAsync, alertas)
                : _buildDesktop(kpisAsync, actividadAsync, alertas),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // MÓVIL
  // ═══════════════════════════════════════════
  Widget _buildMobile(
    AsyncValue<DashboardComprasKpis> kpisAsync,
    AsyncValue<List<ActividadRecienteItem>> actividadAsync,
    int alertas,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _cardCentroCompras(),
        const SizedBox(height: 12),
        kpisAsync.when(
          data: (k) => Column(
            children: [
              _metricBar('Este mes', formatRd(k.comprasEsteMes),
                  const Color(0xFF0D9488)),
              const SizedBox(height: 8),
              _metricBar('A crédito', formatRd(k.aCreditoEsteMes),
                  const Color(0xFF2563EB)),
              const SizedBox(height: 8),
              _metricBar(
                  'Por pagar', formatRd(k.porPagar), const Color(0xFFF59E0B)),
              const SizedBox(height: 8),
              _metricBar(
                  'Vencido', formatRd(k.vencido), const Color(0xFFEF4444)),
            ],
          ),
          loading: () => const Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator())),
          error: (e, _) => Text('$e'),
        ),
        const SizedBox(height: 16),
        _OpCard(
          icon: Icons.add_shopping_cart_rounded,
          title: 'Registrar compra',
          subtitle: 'Nueva orden de compra o gasto menor',
          color: const Color(0xFF3B82F6),
          onTap: () => context.push('/compras/registrar'),
        ),
        const SizedBox(height: 8),
        _OpCard(
          icon: Icons.list_alt_rounded,
          title: 'Lista de compras',
          subtitle: 'Historial, facturas y seguimiento',
          color: const Color(0xFF64748B),
          onTap: () => context.push('/compras/lista'),
        ),
        TextButton(
          onPressed: () => context.goNamed(ListaCuentasPagarPage.routeName),
          child: Text(
            alertas > 0
                ? 'Cuentas por pagar · $alertas →'
                : 'Cuentas por pagar →',
          ),
        ),
        const SizedBox(height: 8),
        Text('Actividad reciente',
            style: AppTypography.labelLarge
                .copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        actividadAsync.when(
          data: (items) {
            final filtrados = _filtrar(items);
            if (filtrados.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Sin compras', textAlign: TextAlign.center),
              );
            }
            return Column(
              children: [
                for (final item in filtrados)
                  ListTile(
                    title: Text(item.proveedorNombre,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: Text(
                        '${_fecha(item.fecha)} · ${_estadoLabel(item.estado)}'),
                    trailing: Text(formatRd(item.total),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    onTap: () => context
                        .push('/compras/detalle/${item.compraId}'),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e'),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // DESKTOP — layout HTML unificado
  // ═══════════════════════════════════════════
  Widget _buildDesktop(
    AsyncValue<DashboardComprasKpis> kpisAsync,
    AsyncValue<List<ActividadRecienteItem>> actividadAsync,
    int alertas,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ═══════ zona principal (tabla amplia) ═══════
          Expanded(
            flex: 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Métricas: ancho fijo para liberar espacio a la tabla ──
                SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      _cardCentroCompras(),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: _deco(),
                          child: kpisAsync.when(
                            data: (k) => Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Métricas Consolidadas',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _metricBar(
                                  'Este mes',
                                  formatRd(k.comprasEsteMes),
                                  const Color(0xFF0D9488),
                                  Icons.calendar_today,
                                ),
                                const SizedBox(height: 6),
                                _metricBar(
                                  'A crédito',
                                  formatRd(k.aCreditoEsteMes),
                                  const Color(0xFF2563EB),
                                  Icons.layers_outlined,
                                ),
                                const SizedBox(height: 6),
                                _metricBar(
                                  'Por pagar',
                                  formatRd(k.porPagar),
                                  const Color(0xFFF59E0B),
                                  Icons.warning_amber_rounded,
                                ),
                                const SizedBox(height: 6),
                                _metricBar(
                                  'Vencido',
                                  formatRd(k.vencido),
                                  const Color(0xFFEF4444),
                                  Icons.schedule,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Filtros de actividad',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _searchCtrl,
                                  onChanged: (v) =>
                                      setState(() => _filtroTexto = v),
                                  style: const TextStyle(fontSize: 12),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Buscar órdenes por proveedor o RNC...',
                                    hintStyle: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      size: 16,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    isDense: true,
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    _chipFiltro('Todos', 'todos'),
                                    _chipFiltro('Pagadas', 'pagada'),
                                    _chipFiltro('A crédito', 'credito'),
                                    _chipFiltro('Pendientes', 'pendiente'),
                                    _chipFiltro('Vencidas', 'vencida'),
                                  ],
                                ),
                              ],
                            ),
                            loading: () => const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            error: (e, _) => Text('$e'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // ── Ops + tabla: todo el espacio restante ──
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: _deco(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'OPERACIONES',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _opTile(
                                    icon: Icons.add,
                                    iconBg: const Color(0xFF3B82F6),
                                    title: 'Registrar compra',
                                    subtitle:
                                        'Nueva orden de compra o gasto [F12]',
                                    onTap: () => context
                                        .push('/compras/registrar'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _opTile(
                                    icon: Icons.description_outlined,
                                    iconBg: const Color(0xFF94A3B8),
                                    title: 'Lista de compras',
                                    subtitle:
                                        'Historial y auditoría tributaria',
                                    onTap: () =>
                                        context.push('/compras/lista'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.fromLTRB(12, 12, 12, 6),
                          decoration: _deco(),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'ACTIVIDAD RECIENTE  (↑ ↓ para navegar)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                color: const Color(0xFFF8FAFC),
                                child: const Row(
                                  children: [
                                    SizedBox(
                                      width: 54,
                                      child: Text('FECHA', style: _hStyle),
                                    ),
                                    Expanded(
                                      flex: 8,
                                      child: Text('PROVEEDOR',
                                          style: _hStyle),
                                    ),
                                    SizedBox(
                                      width: 88,
                                      child: Text('TIPO', style: _hStyle),
                                    ),
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        'MONTO',
                                        textAlign: TextAlign.right,
                                        style: _hStyle,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 84,
                                      child: Text(
                                        'ESTADO',
                                        textAlign: TextAlign.center,
                                        style: _hStyle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: actividadAsync.when(
                                  data: (items) {
                                    final filtrados = _filtrar(items);
                                    if (filtrados.isEmpty) {
                                      return const Center(
                                        child: Text(
                                          'No hay registros',
                                          style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                      );
                                    }
                                    // Auto-seleccionar primera si no hay
                                    if (_seleccionada == null &&
                                        filtrados.isNotEmpty) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        if (mounted &&
                                            _seleccionada == null) {
                                          setState(() => _seleccionada =
                                              filtrados.first);
                                        }
                                      });
                                    }
                                    return Focus(
                                      focusNode: _focusNode,
                                      autofocus: true,
                                      onKeyEvent: (node, event) {
                                        if (event is! KeyDownEvent) {
                                          return KeyEventResult.ignored;
                                        }
                                        final idx = filtrados.indexWhere(
                                          (e) =>
                                              e.compraId ==
                                              _seleccionada?.compraId,
                                        );
                                        if (event.logicalKey ==
                                            LogicalKeyboardKey
                                                .arrowDown) {
                                          final next = (idx + 1)
                                              .clamp(
                                                  0, filtrados.length - 1);
                                          setState(() => _seleccionada =
                                              filtrados[next]);
                                          return KeyEventResult.handled;
                                        }
                                        if (event.logicalKey ==
                                            LogicalKeyboardKey.arrowUp) {
                                          final prev = (idx - 1)
                                              .clamp(
                                                  0, filtrados.length - 1);
                                          setState(() => _seleccionada =
                                              filtrados[prev]);
                                          return KeyEventResult.handled;
                                        }
                                        return KeyEventResult.ignored;
                                      },
                                      child: ListView.builder(
                                        itemCount: filtrados.length,
                                        itemBuilder: (_, i) {
                                          final item = filtrados[i];
                                          final sel = _seleccionada
                                                  ?.compraId ==
                                              item.compraId;
                                          final badge =
                                              _estadoBadge(item.estado);
                                          return Material(
                                            color: sel
                                                ? const Color(0xFFF0FDF4)
                                                : Colors.white,
                                            child: InkWell(
                                              onTap: () => setState(() =>
                                                  _seleccionada = item),
                                              onDoubleTap: () =>
                                                  context.push(
                                                '/compras/detalle/${item.compraId}',
                                              ),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    left: BorderSide(
                                                      width: 4,
                                                      color: sel
                                                          ? const Color(
                                                              0xFF10B981)
                                                          : Colors
                                                              .transparent,
                                                    ),
                                                    bottom:
                                                        const BorderSide(
                                                      color: Color(
                                                          0xFFF1F5F9),
                                                    ),
                                                  ),
                                                ),
                                                padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                  horizontal: 10,
                                                  vertical: 11,
                                                ),
                                                child: Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 54,
                                                      child: Text(
                                                        _fecha(
                                                            item.fecha),
                                                        style:
                                                            const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight
                                                                  .w700,
                                                          color: Color(
                                                              0xFF334155),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 8,
                                                      child: Text(
                                                        item
                                                            .proveedorNombre,
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style:
                                                            const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight
                                                                  .w800,
                                                          color: Color(
                                                              0xFF0F172A),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 88,
                                                      child: Text(
                                                        'Compra',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight
                                                                  .w700,
                                                          color: Color(
                                                              0xFF475569),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 120,
                                                      child: Text(
                                                        formatRd(
                                                            item.total),
                                                        textAlign:
                                                            TextAlign
                                                                .right,
                                                        maxLines: 1,
                                                        softWrap: false,
                                                        overflow:
                                                            TextOverflow
                                                                .fade,
                                                        style:
                                                            const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight
                                                                  .w900,
                                                          color: Color(
                                                              0xFF0F172A),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 84,
                                                      child: Center(
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 8,
                                                            vertical: 3,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                badge.$2,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                          child: Text(
                                                            badge.$1,
                                                            style:
                                                                TextStyle(
                                                              fontSize:
                                                                  11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              color: badge
                                                                  .$3,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  loading: () => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  error: (e, _) =>
                                      Center(child: Text('$e')),
                                ),
                              ),
                              const Divider(height: 10),
                              Row(
                                children: [
                                  const Text(
                                    'Operaciones sobre fila activa:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () => context.goNamed(
                                      ListaCuentasPagarPage.routeName,
                                    ),
                                    child: const Text(
                                      '[F2] Pagar',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.goNamed(
                                      ListaCuentasPagarPage.routeName,
                                    ),
                                    child: const Text(
                                      '[F3] Abono',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
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
          const SizedBox(width: 10),
          // ═══════ totales + detalle ═══════
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: _deco(),
              child: kpisAsync.when(
                data: (k) {
                  final pendientes = k.porPagar + k.vencido;
                  return SingleChildScrollView(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'TOTALES Y RESUMEN DE SALDOS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _resumenFila('Gasto', formatRd(0)),
                      _resumenFila(
                          'Compra', formatRd(k.comprasEsteMes)),
                      _resumenFila('Itbis', formatRd(0)),
                      _resumenFila('Otros', formatRd(0)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'TOTAL COMPRAS MES',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatRd(k.comprasEsteMes),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Total Pendientes',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        formatRd(pendientes),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'RESUMEN POR ESTADO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _resumenFila(
                          'Crédito', formatRd(k.aCreditoEsteMes)),
                      _resumenFila('Vencido', formatRd(k.vencido)),
                      const Divider(height: 20),
                      // Detalle fila seleccionada
                      if (_seleccionada == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Ninguna orden seleccionada',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        )
                      else ...[
                        Text(
                          _seleccionada!.proveedorNombre,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${_seleccionada!.esCredito ? 'Compra a crédito' : 'Compra de contado'} — ${_fecha(_seleccionada!.fecha)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Comprobante Fiscal NCF',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              Text(
                                _seleccionada!.ncf.isEmpty
                                    ? '—'
                                    : _seleccionada!.ncf,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Balance Liquidado',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              Text(
                                formatRd(_seleccionada!.total),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              context.push('/compras/registrar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          child: const Text('[F12] NUEVA COMPRA'),
                        ),
                      ),
                    ],
                  ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (e, _) => Text('$e'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── helpers UI ──
  static const _hStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w900,
    color: Color(0xFF475569),
    letterSpacing: 0.4,
  );

  BoxDecoration _deco() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  Widget _cardCentroCompras() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _deco(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shopping_cart_outlined,
                size: 20, color: Color(0xFF334155)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Centro de compras',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A))),
                SizedBox(height: 2),
                Text(
                  'Registra compras, revisa actividad y controla tus cuentas por pagar',
                  style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                      height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBar(
    String label,
    String value,
    Color color, [
    IconData icon = Icons.calendar_today,
  ]) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.85),
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.75),
                    letterSpacing: 0.4,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipFiltro(String label, String value) {
    final sel = _filtroEstado == value;
    return Material(
      color: sel ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () => setState(() => _filtroEstado = value),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: sel ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _opTile({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: iconBg == const Color(0xFF3B82F6)
          ? const Color(0xFFEFF6FF)
          : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: iconBg == const Color(0xFF3B82F6)
                  ? const Color(0xFFBFDBFE)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF334155))),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF94A3B8),
                            height: 1.25)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resumenFila(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF64748B))),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  List<ActividadRecienteItem> _filtrar(List<ActividadRecienteItem> items) {
    final q = _filtroTexto.trim().toLowerCase();
    return items.where((i) {
      if (q.isNotEmpty) {
        final ok = i.proveedorNombre.toLowerCase().contains(q) ||
            i.ncf.toLowerCase().contains(q);
        if (!ok) return false;
      }
      return switch (_filtroEstado) {
        'pagada' => i.estado == EstadoCompra.pagada,
        'credito' => i.esCredito && i.estado != EstadoCompra.pagada,
        'pendiente' =>
          i.estado == EstadoCompra.confirmada ||
              i.estado == EstadoCompra.registrada ||
              i.estado == EstadoCompra.recibida,
        'vencida' => i.estado == EstadoCompra.vencida,
        _ => true,
      };
    }).toList();
  }

  String _fecha(DateTime f) => DateFormat('d MMM', 'es').format(f);

  String _estadoLabel(EstadoCompra e) => switch (e) {
        EstadoCompra.pagada => 'Pagada',
        EstadoCompra.confirmada => 'Confirmada',
        EstadoCompra.registrada => 'Registrada',
        EstadoCompra.recibida => 'Recibida',
        EstadoCompra.vencida => 'Vencida',
        EstadoCompra.borrador => 'Borrador',
        EstadoCompra.anulada => 'Anulada',
      };

  (String, Color, Color) _estadoBadge(EstadoCompra e) => switch (e) {
        EstadoCompra.pagada => (
            'Pagada',
            const Color(0xFFD1FAE5),
            const Color(0xFF065F46)
          ),
        EstadoCompra.confirmada ||
        EstadoCompra.registrada ||
        EstadoCompra.recibida => (
            e == EstadoCompra.confirmada ? 'A Crédito' : _estadoLabel(e),
            const Color(0xFFDBEAFE),
            const Color(0xFF1E40AF)
          ),
        EstadoCompra.vencida => (
            'Vencida',
            const Color(0xFFFEE2E2),
            const Color(0xFF991B1B)
          ),
        _ => (
            _estadoLabel(e),
            const Color(0xFFF1F5F9),
            const Color(0xFF64748B)
          ),
      };
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
