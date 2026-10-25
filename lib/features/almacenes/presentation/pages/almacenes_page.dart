import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/navigation/safe_back.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/almacenes/domain/entities/almacen.dart';
import 'package:fiscogest_rd/features/almacenes/presentation/providers/almacen_providers.dart';
import 'package:fiscogest_rd/features/almacenes/presentation/widgets/plan_requerido.dart';

class AlmacenesPage extends ConsumerStatefulWidget {
  const AlmacenesPage({super.key});
  static const routeName = 'almacenes';
  static const path = '/almacenes';

  @override
  ConsumerState<AlmacenesPage> createState() => _AlmacenesPageState();
}

class _AlmacenesPageState extends ConsumerState<AlmacenesPage> {
  String _filtro = '';
  String _chip = 'todos'; // todos | activos | inactivos

  static const _bg = Color(0xFFF4F6F9);
  static const _ink = Color(0xFF0D1E34);
  static const _muted = Color(0xFF334155);
  static const _muted2 = Color(0xFF64748B);
  static const _border = Color(0xFFCBD5E1);
  static const _accent = Color(0xFF00A896);
  static const _chipActiveBg = Color(0xFFE0F2FE);
  static const _chipActiveBorder = Color(0xFF38BDF8);
  static const _chipActiveFg = Color(0xFF0369A1);

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(almacenesHabilitadosProvider)) {
      return const PlanRequeridoAlmacenes(titulo: 'Almacenes');
    }
    final mobile = AppBreakpoints.isMobile(context);
    final async = ref.watch(almacenesControllerProvider);

    return AppScaffold(
      title: 'Almacenes',
      subtitle: 'Sucursales, depósitos y stock por ubicación',
      backgroundColor: _bg,
      showAppBar: mobile,
      leading: mobile
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => safeBack(context, fallback: '/'),
            )
          : null,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: mobile ? 560 : 1100),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                mobile ? 16 : 25,
                mobile ? 12 : 25,
                mobile ? 16 : 25,
                24,
              ),
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _accent),
                ),
                error: (e, _) => Center(
                  child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
                ),
                data: (lista) {
                  final activos = lista.where((a) => a.activo).length;
                  final stock = lista.fold<double>(0, (s, a) => s + a.stockTotal);
                  final visible = lista.where((a) {
                    if (_chip == 'activos' && !a.activo) return false;
                    if (_chip == 'inactivos' && a.activo) return false;
                    if (_filtro.contains('__ubic__')) {
                      final d = (a.direccion ?? '').trim();
                      if (d.isEmpty) return false;
                    }
                    final raw = _filtro.replaceAll('__ubic__', '').trim();
                    if (raw.isEmpty) return true;
                    final q = raw.toLowerCase();
                    return a.codigo.toLowerCase().contains(q) ||
                        a.nombre.toLowerCase().contains(q) ||
                        (a.responsable ?? '').toLowerCase().contains(q) ||
                        (a.direccion ?? '').toLowerCase().contains(q);
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header: título + CTA
                      if (mobile) ...[
                        // Sin flecha aquí: AppScaffold ya muestra leading atrás
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: () => _formulario(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text(
                              'Añadir Nuevo Almacén',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 25),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: _ink,
                                  size: 22,
                                ),
                                onPressed: () =>
                                    safeBack(context, fallback: '/'),
                              ),
                              const SizedBox(width: 4),
                              const Expanded(
                                child: Text(
                                  'Almacenes',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                  ),
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: () => _formulario(context),
                                style: FilledButton.styleFrom(
                                  backgroundColor: _accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  elevation: 0,
                                ),
                                icon: const Icon(
                                  Icons.warehouse_outlined,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Añadir Nuevo Almacén',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Filter bar
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: mobile
                            ? Column(
                                children: [
                                  _searchField(),
                                  const SizedBox(height: 10),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(children: _chipWidgets()),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(child: _searchField()),
                                  const SizedBox(width: 12),
                                  ..._chipWidgets(),
                                ],
                              ),
                      ),

                      // Metrics 3-col
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: mobile
                            ? Column(
                                children: [
                                  _metricPrimary(
                                    'Total Almacenes',
                                    '${lista.length}',
                                    '${lista.length} Almacén${lista.length == 1 ? '' : 'es'} Configurado${lista.length == 1 ? '' : 's'}',
                                    Icons.warehouse_outlined,
                                    compact: true,
                                  ),
                                  const SizedBox(height: 10),
                                  _metricPlain(
                                    'Estado Operativo',
                                    '$activos',
                                    '$activos Almacén${activos == 1 ? '' : 'es'} Activo${activos == 1 ? '' : 's'}',
                                    Icons.check_circle,
                                    showBar: true,
                                    ratio: lista.isEmpty
                                        ? 0
                                        : activos / lista.length,
                                    compact: true,
                                  ),
                                  const SizedBox(height: 10),
                                  _metricPlain(
                                    'Inventario Global',
                                    stock.toStringAsFixed(0),
                                    '${stock.toStringAsFixed(0)} Unidades en Stock',
                                    Icons.inventory_2_outlined,
                                    compact: true,
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: _metricPrimary(
                                      'Total Almacenes',
                                      '${lista.length}',
                                      '${lista.length} Almacén${lista.length == 1 ? '' : 'es'} Configurado${lista.length == 1 ? '' : 's'}',
                                      Icons.warehouse_outlined,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _metricPlain(
                                      'Estado Operativo',
                                      '$activos',
                                      '$activos Almacén${activos == 1 ? '' : 'es'} Activo${activos == 1 ? '' : 's'}',
                                      Icons.check_circle_outline,
                                      showBar: true,
                                      ratio: lista.isEmpty
                                          ? 0
                                          : activos / lista.length,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _metricPlain(
                                      'Inventario Global',
                                      stock.toStringAsFixed(0),
                                      '${stock.toStringAsFixed(0)} Unidades en Stock',
                                      Icons.inventory_2_outlined,
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      // Lista
                      Expanded(
                        child: visible.isEmpty
                            ? const Center(
                                child: Text(
                                  'Sin almacenes para este filtro.',
                                  style: TextStyle(color: _muted),
                                ),
                              )
                            : ListView.separated(
                                itemCount: visible.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, i) =>
                                    _almacenCard(visible[i]),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      onChanged: (v) => setState(() => _filtro = v.trim()),
      style: const TextStyle(fontSize: 14, color: _ink),
      decoration: InputDecoration(
        hintText: 'Buscar código, nombre, responsable, o ubicación...',
        hintStyle: const TextStyle(color: _muted2, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: _muted2, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
      ),
    );
  }

  List<Widget> _chipWidgets() {
    final items = <(String, String, Color?, Color?, Color?)>[
      ('todos', 'Todos', null, null, null),
      ('activos', 'Activos', const Color(0xFFD1FAE5), const Color(0xFF34D399), const Color(0xFF047857)),
      ('inactivos', 'Inactivos', const Color(0xFFFEE2E2), const Color(0xFFF87171), const Color(0xFFB91C1C)),
    ];
    return [
      for (final it in items) ...[
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () => setState(() => _chip = it.$1),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _chip == it.$1
                    ? (it.$3 ?? _chipActiveBg)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  width: 1.5,
                  color: _chip == it.$1
                      ? (it.$4 ?? _chipActiveBorder)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: Text(
                it.$2,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _chip == it.$1
                      ? (it.$5 ?? _chipActiveFg)
                      : const Color(0xFF334155),
                ),
              ),
            ),
          ),
        ),
      ],
      InkWell(
        onTap: () {
          setState(() {
            _chip = 'todos';
            // Filtra en vivo los que tienen dirección
            _filtro = _filtro.contains('__ubic__') ? '' : '__ubic__';
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _filtro.contains('__ubic__')
                ? _chipActiveBg
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              width: 1.5,
              color: _filtro.contains('__ubic__')
                  ? _chipActiveBorder
                  : const Color(0xFFCBD5E1),
            ),
          ),
          child: Text(
            'Filtrar por Ubicación',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _filtro.contains('__ubic__')
                  ? _chipActiveFg
                  : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _metricPrimary(
    String label,
    String value,
    String sub,
    IconData icon, {
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00796B), Color(0xFF00A896)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: compact ? 26 : 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE0F2FE),
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, size: 36, color: Colors.white.withValues(alpha: 0.4)),
        ],
      ),
    );
  }

  Widget _metricPlain(
    String label,
    String value,
    String sub,
    IconData icon, {
    bool showBar = false,
    double ratio = 0,
    bool compact = false,
  }) {
    // Estado Operativo: check arriba-derecha + sombra verde degradada
    final isOperativo = showBar;

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
          if (isOperativo)
            BoxShadow(
              color: const Color(0xFF22C55E).withValues(alpha: 0.22),
              blurRadius: 28,
              spreadRadius: -4,
              offset: const Offset(14, -10),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Glow esquina superior derecha (verde → transparente)
          if (isOperativo)
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF22C55E).withValues(alpha: 0.45),
                      const Color(0xFF14532D).withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          // Check arriba-derecha
          if (isOperativo)
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                icon,
                size: 34,
                color: const Color(0xFF16A34A).withValues(alpha: 0.85),
              ),
            ),
          // Contenido
          Padding(
            padding: EdgeInsets.only(right: isOperativo ? 36 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: compact ? 26 : 32,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      if (showBar) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: const Color(0xFFE2E8F0),
                            color: const Color(0xFF4ADE80),
                          ),
                        ),
                      ],
                      const SizedBox(height: 5),
                      Text(
                        sub,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isOperativo)
                  Icon(
                    icon,
                    size: 36,
                    color: _muted2.withValues(alpha: 0.35),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _almacenCard(Almacen a) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _verDetalle(context, a),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < 720;
              final left = Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F2F3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.warehouse_outlined,
                      color: a.activo ? _accent : _muted2,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${a.codigo} · ${a.tipo.label}'
                          '${a.activo ? '' : ' · Inactivo'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Stock: ${a.stockTotal.toStringAsFixed(2)} U    SKUs: ${a.skus}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final mid = Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RESPONSABLE',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a.responsable == null || a.responsable!.isEmpty
                              ? '—'
                              : 'Gestor: ${a.responsable}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'UBICACIÓN',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (a.direccion == null || a.direccion!.isEmpty)
                              ? '—'
                              : a.direccion!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final actions = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => _verDetalle(context, a),
                    style: TextButton.styleFrom(
                      foregroundColor: _accent,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      'view details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: _muted2,
                      size: 20,
                    ),
                    onSelected: (v) async {
                      if (v == 'editar') {
                        await _formulario(context, existente: a);
                      } else if (v == 'principal' && a.id != null) {
                        await ref
                            .read(almacenesControllerProvider.notifier)
                            .marcarPrincipal(a.id!);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Text('Editar'),
                      ),
                      if (!a.esPrincipal)
                        const PopupMenuItem(
                          value: 'principal',
                          child: Text('Marcar como principal'),
                        ),
                    ],
                  ),
                ],
              );

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    left,
                    const SizedBox(height: 12),
                    Container(height: 1.5, color: const Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),
                    mid,
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _verDetalle(context, a),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _accent,
                              side: const BorderSide(
                                color: Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Ver detalles',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 44,
                          height: 40,
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.more_vert,
                              color: Color(0xFF64748B),
                            ),
                            onSelected: (v) async {
                              if (v == 'editar') {
                                await _formulario(context, existente: a);
                              } else if (v == 'principal' && a.id != null) {
                                await ref
                                    .read(
                                      almacenesControllerProvider.notifier,
                                    )
                                    .marcarPrincipal(a.id!);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'editar',
                                child: Text('Editar'),
                              ),
                              if (!a.esPrincipal)
                                const PopupMenuItem(
                                  value: 'principal',
                                  child: Text('Marcar como principal'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 3, child: left),
                  Container(
                    width: 1.5,
                    height: 52,
                    color: const Color(0xFFCBD5E1),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  Expanded(flex: 3, child: mid),
                  actions,
                ],
              );
            },
          ),
        ),
      ),
    );
  }


  void _verDetalle(BuildContext context, Almacen a) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F2F3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.warehouse_outlined,
                        color: a.activo ? _accent : _muted2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.nombre,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '${a.codigo} · ${a.tipo.label}'
                            '${a.activo ? '' : ' · Inactivo'}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _detalleRow('Stock', '${a.stockTotal.toStringAsFixed(2)} U'),
                _detalleRow('SKUs', '${a.skus}'),
                _detalleRow(
                  'Responsable',
                  (a.responsable == null || a.responsable!.isEmpty)
                      ? '—'
                      : a.responsable!,
                ),
                _detalleRow(
                  'Ubicación',
                  (a.direccion == null || a.direccion!.isEmpty)
                      ? '—'
                      : a.direccion!,
                ),
                _detalleRow(
                  'Teléfono',
                  (a.telefono == null || a.telefono!.isEmpty)
                      ? '—'
                      : a.telefono!,
                ),
                _detalleRow('Estado', a.activo ? 'Activo' : 'Inactivo'),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _formulario(context, existente: a);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text(
                    'Editar almacén',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _formulario(BuildContext context, {Almacen? existente}) async {
    final codigoCtrl = TextEditingController(text: existente?.codigo ?? '');
    final nombreCtrl = TextEditingController(text: existente?.nombre ?? '');
    final dirCtrl = TextEditingController(text: existente?.direccion ?? '');
    final telCtrl = TextEditingController(text: existente?.telefono ?? '');
    final respCtrl = TextEditingController(text: existente?.responsable ?? '');
    var tipo = existente?.tipo ?? TipoAlmacen.tienda;
    var activo = existente?.activo ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(
                existente == null ? 'Nuevo almacén' : 'Editar almacén',
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppTextField(
                        controller: codigoCtrl,
                        label: 'Código',
                        hint: 'ALM-02',
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: nombreCtrl,
                        label: 'Nombre',
                        hint: 'Depósito norte',
                      ),
                      const SizedBox(height: 10),
                      InputDecorator(
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<TipoAlmacen>(
                            isExpanded: true,
                            value: tipo,
                            items: [
                              for (final t in TipoAlmacen.values)
                                DropdownMenuItem(
                                  value: t,
                                  child: Text(t.label),
                                ),
                            ],
                            onChanged: (v) {
                              if (v != null) setLocal(() => tipo = v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: dirCtrl,
                        label: 'Dirección (opcional)',
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: telCtrl,
                        label: 'Teléfono (opcional)',
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: respCtrl,
                        label: 'Responsable (opcional)',
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Activo'),
                        value: activo,
                        onChanged: (v) => setLocal(() => activo = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true) return;
    final codigo = codigoCtrl.text.trim();
    final nombre = nombreCtrl.text.trim();
    if (codigo.isEmpty || nombre.isEmpty) {
      FiscoGestNotifications.show(
        const SnackBar(content: Text('Código y nombre son obligatorios')),
      );
      return;
    }
    try {
      await ref
          .read(almacenesControllerProvider.notifier)
          .guardar(
            Almacen(
              id: existente?.id,
              codigo: codigo,
              nombre: nombre,
              tipo: tipo,
              direccion: dirCtrl.text.trim().isEmpty
                  ? null
                  : dirCtrl.text.trim(),
              telefono: telCtrl.text.trim().isEmpty
                  ? null
                  : telCtrl.text.trim(),
              responsable: respCtrl.text.trim().isEmpty
                  ? null
                  : respCtrl.text.trim(),
              activo: activo,
            ),
          );
      FiscoGestNotifications.show(
        const SnackBar(content: Text('Almacén guardado')),
      );
    } catch (e) {
      FiscoGestNotifications.show(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    }
  }
}
