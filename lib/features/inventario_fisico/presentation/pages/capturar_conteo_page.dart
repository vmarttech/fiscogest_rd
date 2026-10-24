import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/diferencia_conteo.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/providers/inventario_fisico_provider.dart';

class CapturarConteoPage extends ConsumerStatefulWidget {
  const CapturarConteoPage({super.key, required this.conteoId});

  static const String routeName = 'capturar-conteo-fisico';
  final int conteoId;

  @override
  ConsumerState<CapturarConteoPage> createState() => _CapturarConteoPageState();
}

class _CapturarConteoPageState extends ConsumerState<CapturarConteoPage> {
  final _busquedaCtrl = TextEditingController();
  final _fisicoCtrl = TextEditingController();
  Producto? _seleccionado;
  bool _guardando = false;
  String _filtro = '';

  static const _bg = Color(0xFFF1F5F9);
  static const _border = Color(0xFFE2E8F0);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF475569);
  static const _teal = Color(0xFF0D9488);

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    _fisicoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarLinea() async {
    final p = _seleccionado;
    if (p == null || p.id == null) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text(
            'Seleccione un producto',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
      return;
    }
    final fisico = double.tryParse(_fisicoCtrl.text.replaceAll(',', '.'));
    if (fisico == null || fisico < 0) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text(
            'Cantidad física inválida',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
      return;
    }
    final sistema = p.stock ?? 0.0;
    final dif = fisico - sistema;
    setState(() => _guardando = true);
    try {
      await ref.read(guardarDiferenciaProvider).call(
            DiferenciaConteo(
              id: 0,
              conteoId: widget.conteoId,
              productoId: p.id!,
              codigoProducto: p.codigo,
              nombreProducto: p.nombre,
              stockSistema: sistema,
              stockFisico: fisico,
              diferencia: dif,
              motivo: null,
              estado: 'pendiente',
            ),
          );
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(
            'Guardado: ${p.nombre} · Dif: ${dif.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
      setState(() {
        _seleccionado = null;
        _fisicoCtrl.clear();
        _busquedaCtrl.clear();
        _filtro = '';
      });
      ref.invalidate(listaConteosProvider);
      ref.invalidate(diferenciasConteoProvider(widget.conteoId));
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
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.conteoId <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/inventario-fisico');
      });
      return const AppScaffold(
        title: 'Capturar',
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0D9488))),
      );
    }

    final isMobile = AppBreakpoints.isMobile(context);
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    final productosAsync = ref.watch(productoControllerProvider);
    final difsAsync = ref.watch(diferenciasConteoProvider(widget.conteoId));

    int lineas = 0;
    int conDif = 0;
    difsAsync.whenData((d) {
      lineas = d.length;
      conDif = d.where((x) => x.diferencia != 0).length;
    });

    return AppScaffold(
      title: isMobile ? 'Capturar #${widget.conteoId}' : null,
      showAppBar: isMobile,
      backgroundColor: _bg,
      actions: isMobile
          ? [
              IconButton(
                tooltip: 'Diferencias',
                icon: const Icon(Icons.difference_outlined),
                onPressed: () => context
                    .push('/diferencias-conteo-fisico/${widget.conteoId}'),
              ),
            ]
          : const [],
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 24,
          isMobile ? 12 : 20,
          isMobile ? 16 : 24,
          32,
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
                            colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                          ),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Capturar conteo #${widget.conteoId}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: _textPrimary,
                              ),
                            ),
                            const Text(
                              'Registre cantidades físicas por producto',
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
                        onPressed: () => context.push(
                          '/diferencias-conteo-fisico/${widget.conteoId}',
                        ),
                        icon: const Icon(Icons.difference_outlined, size: 18),
                        label: const Text(
                          'Ver diferencias',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _teal,
                          side: const BorderSide(color: _teal),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                // KPIs resumen
                Row(
                  children: [
                    Expanded(
                      child: _miniKpi(
                        'Líneas',
                        '$lineas',
                        Icons.playlist_add_check_rounded,
                        const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _miniKpi(
                        'Con diferencia',
                        '$conDif',
                        Icons.warning_amber_rounded,
                        conDif > 0
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _panelCaptura(productosAsync, isMobile)),
                      const SizedBox(width: 16),
                      Expanded(flex: 5, child: _panelLineas(difsAsync)),
                    ],
                  )
                else ...[
                  _panelCaptura(productosAsync, isMobile),
                  const SizedBox(height: 14),
                  _panelLineas(difsAsync),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniKpi(String label, String value, IconData icon, Color accent) {
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

  Widget _panelCaptura(AsyncValue<List<Producto>> productosAsync, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Agregar producto',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _busquedaCtrl,
            onChanged: (v) =>
                setState(() => _filtro = v.trim().toLowerCase()),
            style: const TextStyle(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'Buscar por código o nombre…',
              hintStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: _teal, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          productosAsync.when(
            loading: () => const LinearProgressIndicator(color: _teal),
            error: (e, _) => Text(
              'Error productos: $e',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626),
              ),
            ),
            data: (lista) {
              final filtrados = _filtro.isEmpty
                  ? lista.take(8).toList()
                  : lista
                      .where((p) =>
                          p.codigo.toLowerCase().contains(_filtro) ||
                          p.nombre.toLowerCase().contains(_filtro))
                      .take(12)
                      .toList();
              if (filtrados.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Sin resultados',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final p in filtrados) _productoTile(p),
                ],
              );
            },
          ),
          if (_seleccionado != null) ...[
            const Divider(height: 28),
            Text(
              _seleccionado!.nombre,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sistema: ${(_seleccionado!.stock ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _textMuted,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fisicoCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Cantidad física',
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: _teal, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _guardando ? null : _guardarLinea,
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(
                  _guardando ? 'Guardando…' : 'Guardar línea',
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
          ],
        ],
      ),
    );
  }

  Widget _productoTile(Producto p) {
    final sel = _seleccionado?.id == p.id;
    return Material(
      color: sel ? const Color(0xFFCCFBF1) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          setState(() {
            _seleccionado = p;
            _fisicoCtrl.text = (p.stock ?? 0).toString();
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(
                sel ? Icons.check_circle_rounded : Icons.inventory_2_outlined,
                size: 18,
                color: sel ? _teal : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      '${p.codigo} · Stock ${(p.stock ?? 0).toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
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

  Widget _panelLineas(AsyncValue<List<DiferenciaConteo>> difsAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Líneas registradas',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          difsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: _teal)),
            ),
            error: (e, _) => Text(
              'Error: $e',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626),
              ),
            ),
            data: (difs) {
              if (difs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 36, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 8),
                      Text(
                        'Aún no hay líneas en este conteo',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  for (final d in difs) ...[
                    _lineaCard(d),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _lineaCard(DiferenciaConteo d) {
    final color = d.diferencia == 0
        ? const Color(0xFF64748B)
        : (d.diferencia > 0
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
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
                    fontSize: 13.5,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${d.codigoProducto} · Sis ${d.stockSistema.toStringAsFixed(1)} · Fís ${d.stockFisico.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Text(
            d.diferencia > 0
                ? '+${d.diferencia.toStringAsFixed(1)}'
                : d.diferencia.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
