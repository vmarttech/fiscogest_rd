import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/ajuste_inventario.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/presentation/pages/registrar_ajuste_page.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/presentation/providers/ajuste_inventario_provider.dart';

/// Lista de ajustes — mismo diseño que Inventario Físico (KPIs, filtros, cards).
class ListaAjustesPage extends ConsumerStatefulWidget {
  const ListaAjustesPage({super.key});
  static const String routeName = 'lista-ajustes';

  @override
  ConsumerState<ListaAjustesPage> createState() => _ListaAjustesPageState();
}

class _ListaAjustesPageState extends ConsumerState<ListaAjustesPage> {
  String _filtro = '';
  String? _tipoFiltro; // null | entrada | salida

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
    return '${d.day.toString().padLeft(2, '0')} ${m[d.month - 1]} ${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Color _colorTipo(String tipo) {
    final t = tipo.toLowerCase();
    if (t == 'salida' || t == 'merma') return const Color(0xFFDC2626);
    if (t == 'entrada') return const Color(0xFF16A34A);
    return const Color(0xFF2563EB);
  }

  void _nuevo() => context.pushNamed(RegistrarAjustePage.routeName);

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final listaAsync = ref.watch(ajusteInventarioListaProvider);

    return AppScaffold(
      title: isMobile ? 'Lista de Ajustes' : null,
      showAppBar: isMobile,
      backgroundColor: _bg,
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              onPressed: _nuevo,
              backgroundColor: _teal,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Nuevo',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          : null,
      body: listaAsync.when(
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
          final entradas = lista
              .where((a) => a.tipoAjuste.toLowerCase() == 'entrada')
              .length;
          final salidas = lista
              .where((a) {
                final t = a.tipoAjuste.toLowerCase();
                return t == 'salida' || t == 'merma';
              })
              .length;
          final otros = total - entradas - salidas;

          var filtrados = lista;
          if (_tipoFiltro != null) {
            filtrados = filtrados
                .where((a) => a.tipoAjuste.toLowerCase() == _tipoFiltro)
                .toList();
          }
          if (_filtro.isNotEmpty) {
            final q = _filtro;
            filtrados = filtrados.where((a) {
              return a.productoId.toString().contains(q) ||
                  (a.codigoBusqueda ?? '').toLowerCase().contains(q) ||
                  a.tipoAjuste.toLowerCase().contains(q) ||
                  a.motivo.toLowerCase().contains(q);
            }).toList();
          }
          filtrados = [...filtrados]
            ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

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
                    // —— Cabecera (mismo patrón móvil y desktop) ——
                    if (!isMobile) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF0D9488),
                                  Color(0xFF14B8A6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lista de Ajustes',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: _textPrimary,
                                  ),
                                ),
                                Text(
                                  'Correcciones de stock y mermas',
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
                            onPressed: _nuevo,
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text(
                              'Nuevo ajuste',
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
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _nuevo,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text(
                            'Nuevo ajuste',
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

                    // —— KPIs ——
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
                                  () => setState(() => _tipoFiltro = null),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _kpi(
                                  'Entradas',
                                  '$entradas',
                                  Icons.add_circle_outline,
                                  const Color(0xFF16A34A),
                                  () => setState(() {
                                    _tipoFiltro =
                                        _tipoFiltro == 'entrada'
                                            ? null
                                            : 'entrada';
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
                                  'Salidas',
                                  '$salidas',
                                  Icons.remove_circle_outline,
                                  const Color(0xFFDC2626),
                                  () => setState(() {
                                    _tipoFiltro =
                                        _tipoFiltro == 'salida'
                                            ? null
                                            : 'salida';
                                  }),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _kpi(
                                  'Otros',
                                  '$otros',
                                  Icons.tune_rounded,
                                  const Color(0xFF2563EB),
                                  null,
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
                              () => setState(() => _tipoFiltro = null),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _kpi(
                              'Entradas',
                              '$entradas',
                              Icons.add_circle_outline,
                              const Color(0xFF16A34A),
                              () => setState(() {
                                _tipoFiltro =
                                    _tipoFiltro == 'entrada' ? null : 'entrada';
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _kpi(
                              'Salidas',
                              '$salidas',
                              Icons.remove_circle_outline,
                              const Color(0xFFDC2626),
                              () => setState(() {
                                _tipoFiltro =
                                    _tipoFiltro == 'salida' ? null : 'salida';
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _kpi(
                              'Otros',
                              '$otros',
                              Icons.tune_rounded,
                              const Color(0xFF2563EB),
                              null,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // —— Buscar ——
                    TextField(
                      onChanged: (v) =>
                          setState(() => _filtro = v.trim().toLowerCase()),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: 'Buscar producto, tipo o motivo…',
                        hintStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF94A3B8),
                        ),
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

                    // —— Chips tipo ——
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _chip('Todos', _tipoFiltro == null, () {
                            setState(() => _tipoFiltro = null);
                          }),
                          const SizedBox(width: 6),
                          _chip(
                            'Entrada',
                            _tipoFiltro == 'entrada',
                            () => setState(() {
                              _tipoFiltro =
                                  _tipoFiltro == 'entrada' ? null : 'entrada';
                            }),
                          ),
                          const SizedBox(width: 6),
                          _chip(
                            'Salida',
                            _tipoFiltro == 'salida',
                            () => setState(() {
                              _tipoFiltro =
                                  _tipoFiltro == 'salida' ? null : 'salida';
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const Text(
                          'Ajustes',
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
                            Icon(
                              Icons.tune_outlined,
                              size: 40,
                              color: Color(0xFFCBD5E1),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'No hay ajustes con estos filtros',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      for (final a in filtrados) ...[
                        _ajusteCard(a, isMobile),
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
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _textMuted,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: accent,
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? const Color(0xFF0F172A) : _border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ajusteCard(AjusteInventario a, bool isMobile) {
    final color = _colorTipo(a.tipoAjuste);
    final titulo = (a.codigoBusqueda != null && a.codigoBusqueda!.isNotEmpty)
        ? a.codigoBusqueda!
        : 'Producto #${a.productoId}';

    // Misma card en móvil y desktop (solo tipografía / padding varía un poco)
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 16,
                    fontWeight: FontWeight.w900,
                    color: _textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  a.tipoAjuste,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge(
                'Cant. ${a.cantidad}',
                color,
              ),
              _badge(
                _fmtFecha(a.fechaCreacion),
                const Color(0xFF64748B),
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Text(
              a.motivo,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
