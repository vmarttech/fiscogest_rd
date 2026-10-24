import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/providers/core_providers.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/diferencia_conteo.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/providers/inventario_fisico_provider.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';

class DiferenciasConteoPage extends ConsumerStatefulWidget {
  const DiferenciasConteoPage({super.key, required this.conteoId});

  static const routeName = 'diferencias-conteo-fisico';
  final int conteoId;

  @override
  ConsumerState<DiferenciasConteoPage> createState() =>
      _DiferenciasConteoPageState();
}

enum _FiltroDif { todas, soloDif, faltantes, sobrantes }

class _DiferenciasConteoPageState extends ConsumerState<DiferenciasConteoPage> {
  bool _aprobando = false;
  _FiltroDif _filtro = _FiltroDif.todas;

  static const _bg = Color(0xFFF1F5F9);
  static const _border = Color(0xFFE2E8F0);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF475569);
  static const _teal = Color(0xFF0D9488);

  Future<void> _aprobar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Aprobar ajustes',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Se actualizará el stock de cada producto al valor físico contado. ¿Continuar?',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _teal),
            child: const Text(
              'Aprobar',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _aprobando = true);
    try {
      final uid = ref.read(usuarioAutenticadoProvider);
      if (uid == null) {
        if (mounted) {
          FiscoGestNotifications.show(
            const SnackBar(
              content: Text(
                'No hay sesión activa',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          );
        }
        return;
      }
      await ref.read(aprobarAjustesProvider).call(widget.conteoId, uid);
      ref.invalidate(diferenciasConteoProvider(widget.conteoId));
      ref.invalidate(listaConteosProvider);
      ref.invalidate(productoControllerProvider);
      if (mounted) {
        FiscoGestNotifications.show(
          const SnackBar(
            content: Text(
              'Ajustes aplicados y conteo aprobado',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        FiscoGestNotifications.show(
          SnackBar(
            content: Text(
              'Error: $e',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _aprobando = false);
    }
  }

  Future<void> _exportarReporte() async {
    try {
      final bytes =
          await ref.read(generarReporteProvider).call(widget.conteoId);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'conteo_${widget.conteoId}.pdf',
      );
    } catch (e) {
      if (mounted) {
        FiscoGestNotifications.show(
          SnackBar(
            content: Text(
              'Error reporte: $e',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      }
    }
  }

  List<DiferenciaConteo> _aplicarFiltro(List<DiferenciaConteo> lista) {
    switch (_filtro) {
      case _FiltroDif.todas:
        return lista;
      case _FiltroDif.soloDif:
        return lista.where((d) => d.diferencia != 0).toList();
      case _FiltroDif.faltantes:
        return lista.where((d) => d.diferencia < 0).toList();
      case _FiltroDif.sobrantes:
        return lista.where((d) => d.diferencia > 0).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.conteoId <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/inventario-fisico');
      });
      return const AppScaffold(
        title: 'Diferencias',
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0D9488))),
      );
    }

    final isMobile = AppBreakpoints.isMobile(context);
    final async = ref.watch(diferenciasConteoProvider(widget.conteoId));

    return AppScaffold(
      title: isMobile ? 'Diferencias #${widget.conteoId}' : null,
      showAppBar: isMobile,
      backgroundColor: _bg,
      actions: isMobile
          ? [
              IconButton(
                tooltip: 'PDF',
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: _exportarReporte,
              ),
            ]
          : const [],
      body: async.when(
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
          final conDif = lista.where((d) => d.diferencia != 0).length;
          final ok = lista.where((d) => d.diferencia == 0).length;
          final faltantes = lista.where((d) => d.diferencia < 0).length;
          final filtrados = _aplicarFiltro(lista);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24,
                    isMobile ? 12 : 20,
                    isMobile ? 16 : 24,
                    16,
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
                                IconButton(
                                  onPressed: () {
                                    if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go('/inventario-fisico');
                                    }
                                  },
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  tooltip: 'Atrás',
                                ),

                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF0D9488),
                                        Color(0xFF14B8A6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: const Icon(
                                    Icons.balance_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Diferencias #${widget.conteoId}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: _textPrimary,
                                        ),
                                      ),
                                      const Text(
                                        'Sistema vs físico',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _exportarReporte,
                                  icon: const Icon(
                                      Icons.picture_as_pdf_outlined,
                                      size: 18),
                                  label: const Text(
                                    'Exportar PDF',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _teal,
                                    side: const BorderSide(color: _teal),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                FilledButton.icon(
                                  onPressed: _aprobando ? null : _aprobar,
                                  icon: _aprobando
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.check_rounded,
                                          size: 18),
                                  label: Text(
                                    _aprobando
                                        ? 'Aplicando…'
                                        : 'Aprobar ajustes',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _teal,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                          ],
                          // KPIs
                          if (isMobile)
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _kpi('Total', '$total',
                                          Icons.list_alt, const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _kpi(
                                        'Con dif.',
                                        '$conDif',
                                        Icons.warning_amber_rounded,
                                        conDif > 0
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFF16A34A),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _kpi('OK', '$ok',
                                          Icons.check_circle_outline,
                                          const Color(0xFF16A34A)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _kpi(
                                        'Faltantes',
                                        '$faltantes',
                                        Icons.trending_down_rounded,
                                        const Color(0xFFD97706),
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
                                  child: _kpi('Total líneas', '$total',
                                      Icons.list_alt, const Color(0xFF64748B)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _kpi(
                                    'Con diferencia',
                                    '$conDif',
                                    Icons.warning_amber_rounded,
                                    conDif > 0
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF16A34A),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _kpi('OK', '$ok',
                                      Icons.check_circle_outline,
                                      const Color(0xFF16A34A)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _kpi(
                                    'Faltantes',
                                    '$faltantes',
                                    Icons.trending_down_rounded,
                                    const Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _chip('Todas', _filtro == _FiltroDif.todas,
                                    () => setState(
                                        () => _filtro = _FiltroDif.todas)),
                                const SizedBox(width: 6),
                                _chip(
                                    'Solo diferencias',
                                    _filtro == _FiltroDif.soloDif,
                                    () => setState(
                                        () => _filtro = _FiltroDif.soloDif)),
                                const SizedBox(width: 6),
                                _chip(
                                    'Faltantes',
                                    _filtro == _FiltroDif.faltantes,
                                    () => setState(() =>
                                        _filtro = _FiltroDif.faltantes)),
                                const SizedBox(width: 6),
                                _chip(
                                    'Sobrantes',
                                    _filtro == _FiltroDif.sobrantes,
                                    () => setState(() =>
                                        _filtro = _FiltroDif.sobrantes)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (filtrados.isEmpty)
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 48),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _border),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.inbox_outlined,
                                      size: 40, color: Color(0xFFCBD5E1)),
                                  SizedBox(height: 10),
                                  Text(
                                    'Sin resultados con este filtro',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            for (final d in filtrados) ...[
                              _difCard(d),
                              const SizedBox(height: 8),
                            ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (isMobile)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _aprobando ? null : _aprobar,
                        icon: _aprobando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(
                          _aprobando ? 'Aplicando…' : 'Aprobar ajustes',
                          style: const TextStyle(
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
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _kpi(String label, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
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

  Widget _difCard(DiferenciaConteo d) {
    final color = d.diferencia == 0
        ? const Color(0xFF64748B)
        : (d.diferencia > 0
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              d.diferencia == 0
                  ? Icons.check_rounded
                  : (d.diferencia > 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.nombreProducto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${d.codigoProducto} · Sis ${d.stockSistema.toStringAsFixed(1)} · Fís ${d.stockFisico.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                if (d.estado.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    d.estado,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            d.diferencia > 0
                ? '+${d.diferencia.toStringAsFixed(1)}'
                : d.diferencia.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
