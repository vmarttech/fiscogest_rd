import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/conteo_fisico.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/estado_conteo.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/pages/capturar_conteo_page.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/providers/inventario_fisico_provider.dart';

/// Lista de conteos — KPIs activos, filtros, cards móviles / tabla desktop.
class ListarConteosPage extends ConsumerStatefulWidget {
  const ListarConteosPage({super.key});

  static const routeName = 'lista-conteos-fisicos';

  @override
  ConsumerState<ListarConteosPage> createState() => _ListarConteosPageState();
}

class _ListarConteosPageState extends ConsumerState<ListarConteosPage> {
  String _filtro = '';
  EstadoConteo? _estadoFiltro;

  static const _bg = Color(0xFFF1F5F9);
  static const _border = Color(0xFFE2E8F0);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF475569);
  static const _teal = Color(0xFF0D9488);

  String _fmtFecha(DateTime d) {
    const m = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${m[d.month - 1]} ${d.year}';
  }

  Color _colorEstado(EstadoConteo e) {
    switch (e) {
      case EstadoConteo.pendiente:
        return const Color(0xFFD97706);
      case EstadoConteo.abierto:
      case EstadoConteo.enProceso:
        return const Color(0xFF2563EB);
      case EstadoConteo.conciliado:
        return const Color(0xFF7C3AED);
      case EstadoConteo.aprobado:
        return const Color(0xFF16A34A);
      case EstadoConteo.cancelado:
        return const Color(0xFFDC2626);
    }
  }

  void _abrirConteo(ConteoFisico c) {
    final id = c.id ?? 0;
    final cerrado = c.estado == EstadoConteo.aprobado ||
        c.estado == EstadoConteo.conciliado;
    if (cerrado) {
      context.push('/diferencias-conteo-fisico/$id');
    } else {
      context.pushNamed(
        CapturarConteoPage.routeName,
        pathParameters: {'conteoId': '$id'},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final conteosAsync = ref.watch(listaConteosProvider);

    return AppScaffold(
      title: isMobile ? 'Inventario Físico' : null,
      showAppBar: isMobile,
      backgroundColor: _bg,
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/inventario-fisico'),
              backgroundColor: _teal,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Nuevo',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          : null,
      body: conteosAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _teal),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFFDC2626),
            ),
          ),
        ),
        data: (lista) {
          final total = lista.length;
          final abiertos = lista
              .where((c) =>
                  c.estado == EstadoConteo.pendiente ||
                  c.estado == EstadoConteo.abierto ||
                  c.estado == EstadoConteo.enProceso)
              .length;
          final enProceso = lista
              .where((c) => c.estado == EstadoConteo.enProceso)
              .length;
          final aprobados = lista
              .where((c) => c.estado == EstadoConteo.aprobado)
              .length;

          var filtrados = lista;
          if (_estadoFiltro != null) {
            filtrados =
                filtrados.where((c) => c.estado == _estadoFiltro).toList();
          }
          if (_filtro.isNotEmpty) {
            final q = _filtro.toLowerCase();
            filtrados = filtrados
                .where((c) => c.nombreConteo.toLowerCase().contains(q))
                .toList();
          }
          filtrados = [...filtrados]
            ..sort((a, b) => b.fechaConteo.compareTo(a.fechaConteo));

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 24,
              isMobile ? 12 : 20,
              isMobile ? 16 : 24,
              isMobile ? 88 : 32,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isMobile) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.inventory_2_outlined,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Inventario Físico',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: _textPrimary,
                                  ),
                                ),
                                Text(
                                  'Historial de conteos y estados',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () =>
                                context.push('/inventario-fisico'),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text(
                              'Nuevo conteo',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: _teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (isMobile) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () =>
                              context.push('/inventario-fisico'),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text(
                            'Nuevo conteo',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    // KPIs
                    if (isMobile)
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _kpi(
                                  'Total',
                                  '$total',
                                  Icons.list_alt_rounded,
                                  const Color(0xFF64748B),
                                  null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _kpi(
                                  'Abiertos',
                                  '$abiertos',
                                  Icons.lock_open_rounded,
                                  const Color(0xFF2563EB),
                                  () => setState(() {
                                    _estadoFiltro =
                                        _estadoFiltro == EstadoConteo.abierto
                                            ? null
                                            : EstadoConteo.abierto;
                                  }),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _kpi(
                                  'En proceso',
                                  '$enProceso',
                                  Icons.hourglass_top_rounded,
                                  const Color(0xFFD97706),
                                  () => setState(() {
                                    _estadoFiltro = _estadoFiltro ==
                                            EstadoConteo.enProceso
                                        ? null
                                        : EstadoConteo.enProceso;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _kpi(
                                  'Aprobados',
                                  '$aprobados',
                                  Icons.check_circle_outline,
                                  const Color(0xFF16A34A),
                                  () => setState(() {
                                    _estadoFiltro =
                                        _estadoFiltro == EstadoConteo.aprobado
                                            ? null
                                            : EstadoConteo.aprobado;
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _kpi(
                              'Total',
                              '$total',
                              Icons.list_alt_rounded,
                              const Color(0xFF64748B),
                              () => setState(() => _estadoFiltro = null),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _kpi(
                              'Abiertos',
                              '$abiertos',
                              Icons.lock_open_rounded,
                              const Color(0xFF2563EB),
                              () => setState(() {
                                _estadoFiltro =
                                    _estadoFiltro == EstadoConteo.abierto
                                        ? null
                                        : EstadoConteo.abierto;
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _kpi(
                              'En proceso',
                              '$enProceso',
                              Icons.hourglass_top_rounded,
                              const Color(0xFFD97706),
                              () => setState(() {
                                _estadoFiltro =
                                    _estadoFiltro == EstadoConteo.enProceso
                                        ? null
                                        : EstadoConteo.enProceso;
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _kpi(
                              'Aprobados',
                              '$aprobados',
                              Icons.check_circle_outline,
                              const Color(0xFF16A34A),
                              () => setState(() {
                                _estadoFiltro =
                                    _estadoFiltro == EstadoConteo.aprobado
                                        ? null
                                        : EstadoConteo.aprobado;
                              }),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    // Buscar + chips
                    TextField(
                      onChanged: (v) =>
                          setState(() => _filtro = v.trim().toLowerCase()),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: 'Buscar conteo…',
                        hintStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: _teal, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _chip('Todos', _estadoFiltro == null, () {
                            setState(() => _estadoFiltro = null);
                          }),
                          const SizedBox(width: 6),
                          for (final e in [
                            EstadoConteo.pendiente,
                            EstadoConteo.abierto,
                            EstadoConteo.enProceso,
                            EstadoConteo.conciliado,
                            EstadoConteo.aprobado,
                          ]) ...[
                            _chip(
                              e.etiqueta,
                              _estadoFiltro == e,
                              () => setState(() {
                                _estadoFiltro =
                                    _estadoFiltro == e ? null : e;
                              }),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Conteos',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: _textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${filtrados.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (filtrados.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _border),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 40, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 10),
                            Text(
                              'No hay conteos con estos filtros',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      for (final c in filtrados) ...[
                        _conteoCard(c, isMobile),
                        const SizedBox(height: 8),
                      ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _kpi(
    String label,
    String value,
    IconData icon,
    Color accent,
    VoidCallback? onTap,
  ) {
    final body = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: body,
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? const Color(0xFF0F172A) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? const Color(0xFF0F172A) : _border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : _textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _conteoCard(ConteoFisico c, bool isMobile) {
    final color = _colorEstado(c.estado);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _abrirConteo(c),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.assignment_outlined, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.nombreConteo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _fmtFecha(c.fechaConteo),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            c.estado.etiqueta,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
