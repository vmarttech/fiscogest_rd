import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/kardex_provider.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/categoria_providers.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/categoria.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/providers/core_providers.dart';

class KardexPage extends ConsumerStatefulWidget {
  const KardexPage({super.key, this.productoId});
  static const String routeName = 'kardex';
  final String? productoId;

  @override
  ConsumerState<KardexPage> createState() => _KardexPageState();
}

class _KardexPageState extends ConsumerState<KardexPage> {
  late final int? _productoIdFijo;
  String _filtroBusqueda = '';
  TipoMovimiento? _filtroTipo;
  DateTime? _filtroFecha;
  String _filtroUsuario = '';
  int? _filtroCategoriaId;
  int _pagina = 1;
  int _porPagina = 15;

  static const _bgMain = Color(0xFFF8FAFC);
  static const _border = Color(0xFFE2E8F0);
  static const _textPrimary = Color(0xFF1E293B);
  static const _textMuted = Color(0xFF64748B);
  static const _teal = Color(0xFF00796B);

  @override
  void initState() {
    super.initState();
    _productoIdFijo = widget.productoId != null
        ? int.tryParse(widget.productoId!.replaceAll(RegExp(r'[^0-9]'), ''))
        : null;
  }

  String _fmtNum(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  String _fmtMoney(double v) {
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '\$$intPart.${parts[1]}';
  }

  String _fmtFecha(DateTime? f) {
    final d = f ?? DateTime.now();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  String _labelTipo(TipoMovimiento t) => switch (t) {
        TipoMovimiento.entrada => 'ENTRADA',
        TipoMovimiento.salida => 'SALIDA',
        TipoMovimiento.ajuste => 'AJUSTE',
        TipoMovimiento.transferencia => 'TRANSFERENCIA',
        TipoMovimiento.devolucion => 'DEVOLUCIÓN',
        TipoMovimiento.traslado => 'TRASLADO',
      };

  bool _esEntrada(TipoMovimiento t) =>
      t == TipoMovimiento.entrada ||
      t == TipoMovimiento.devolucion ||
      t == TipoMovimiento.ajuste;

  List<Kardex> _filtrar(
    List<Kardex> movimientos, {
    required Map<int, Producto> productos,
  }) {
    final q = _filtroBusqueda.trim().toLowerCase();
    final uq = _filtroUsuario.trim().toLowerCase();

    return movimientos.where((mov) {
      if (_productoIdFijo != null && mov.productoId != _productoIdFijo) {
        return false;
      }
      final prod = productos[mov.productoId];
      if (_filtroCategoriaId != null) {
        if (prod == null || prod.categoriaId != _filtroCategoriaId) {
          return false;
        }
      }
      if (q.isNotEmpty) {
        final doc = (mov.documentoReferencia ?? '').toLowerCase();
        final obs = (mov.observacion ?? '').toLowerCase();
        final pid = mov.productoId.toString();
        final pn = (prod?.nombre ?? '').toLowerCase();
        final pc = (prod?.codigo ?? '').toLowerCase();
        if (!doc.contains(q) &&
            !obs.contains(q) &&
            !pid.contains(q) &&
            !pn.contains(q) &&
            !pc.contains(q)) {
          return false;
        }
      }
      if (_filtroTipo != null && mov.tipoMovimiento != _filtroTipo) {
        return false;
      }
      if (_filtroFecha != null && mov.fechaMovimiento != null) {
        final f = mov.fechaMovimiento!;
        if (f.year != _filtroFecha!.year ||
            f.month != _filtroFecha!.month ||
            f.day != _filtroFecha!.day) {
          return false;
        }
      }
      if (uq.isNotEmpty) {
        final uid = mov.usuarioId.toString();
        if (!uid.contains(uq)) return false;
      }
      return true;
    }).toList();
  }

  /// Quita palabras consecutivas repetidas: "Sistema Sistema" → "Sistema".
  String _dedupeWords(String raw) {
    final out = <String>[];
    for (final w in raw.trim().split(RegExp(r'\s+'))) {
      if (w.isEmpty) continue;
      if (out.isEmpty || out.last.toLowerCase() != w.toLowerCase()) {
        out.add(w);
      }
    }
    return out.join(' ');
  }

  Future<Map<int, String>> _cargarNombresUsuario() async {
    try {
      final db = ref.read(databaseProvider);
      final rows = await db.select(db.usuariosTable).get();
      final map = <int, String>{};
      for (final u in rows) {
        final nom = _dedupeWords(u.nombre);
        var ape = _dedupeWords(u.apellido ?? '');
        // Si el apellido ya está contenido en el nombre, no lo concatenamos.
        if (ape.isNotEmpty &&
            nom.toLowerCase().split(RegExp(r'\s+')).contains(ape.toLowerCase())) {
          ape = '';
        }
        if (ape.isNotEmpty &&
            nom.toLowerCase().endsWith(ape.toLowerCase())) {
          ape = '';
        }
        String full;
        if (nom.isEmpty && ape.isEmpty) {
          full = (u.username).trim();
        } else if (ape.isEmpty) {
          full = nom;
        } else {
          full = '$nom $ape';
        }
        full = _dedupeWords(full);
        if (full.length > 36) {
          full = '${full.substring(0, 33)}…';
        }
        map[u.id] = full.isEmpty ? 'Usuario ${u.id}' : full;
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  void _verDocumento(
    Kardex mov, {
    required Map<int, Producto> productos,
    required Map<int, String> usuarios,
    required Map<int, String> categorias,
  }) {
    final prod = productos[mov.productoId];
    final nombreProd = prod?.nombre ?? 'Producto #${mov.productoId}';
    final cat = prod != null
        ? (categorias[prod.categoriaId] ?? 'Sin categoría')
        : '—';
    final user = usuarios[mov.usuarioId] ?? 'Usuario #${mov.usuarioId}';
    final doc = (mov.documentoReferencia ?? '').trim();
    final entrada = _esEntrada(mov.tipoMovimiento);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // ~50% del ancho habitual del sheet a pantalla completa
      constraints: BoxConstraints(
        maxWidth: (MediaQuery.sizeOf(context).width * 0.5).clamp(280.0, 420.0),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: entrada
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _labelTipo(mov.tipoMovimiento),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: entrada
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _fmtFecha(mov.fechaMovimiento),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                doc.isEmpty ? 'Sin documento' : doc,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                (mov.observacion ?? '').trim().isEmpty
                    ? 'Sin observación'
                    : mov.observacion!.trim(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _textMuted,
                ),
              ),
              const SizedBox(height: 18),
              _detailRow('Producto', nombreProd),
              _detailRow('Código', prod?.codigo ?? '—'),
              _detailRow('Categoría', cat),
              _detailRow('Usuario', user),
              _detailRow('ID usuario', '${mov.usuarioId}'),
              _detailRow('Cantidad', _fmtNum(mov.cantidad)),
              _detailRow('Costo unit.', _fmtMoney(mov.costoUnitario)),
              _detailRow('Valor total', _fmtMoney(mov.totalMovimiento)),
              _detailRow(
                'Saldo',
                '${_fmtNum(mov.saldoAnterior)} → ${_fmtNum(mov.saldoNuevo)}',
              ),
              const SizedBox(height: 16),
              if (_puedeAbrirDocumento(doc))
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _abrirDocumentoRelacionado(doc);
                  },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text(
                    'Abrir documento relacionado',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(fontWeight: FontWeight.w700),
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

  Widget _detailRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              k,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _textMuted,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _puedeAbrirDocumento(String doc) {
    final d = doc.trim().toLowerCase();
    if (d.isEmpty || d == 'sin documento') return false;
    return d.startsWith('factura') ||
        d.startsWith('venta') ||
        d.startsWith('nc ') ||
        d.contains('factura ') ||
        d.startsWith('ajuste') ||
        d.startsWith('conteo');
  }

  /// Ej: "Factura B0200000013" → factura/B0200000013
  ///     "Venta #42" → venta/42
  ///     "NC E32… / Factura B02…" → factura/B02…
  ({String tipo, String ref})? _parseDocRef(String doc) {
    final d = doc.trim();
    if (d.isEmpty) return null;

    final factura = RegExp(
      r'Factura\s+([A-Za-z0-9\-]+)',
      caseSensitive: false,
    ).firstMatch(d);
    if (factura != null) {
      return (tipo: 'factura', ref: factura.group(1)!.trim());
    }

    final venta = RegExp(
      r'Venta\s*#\s*([A-Za-z0-9\-]+)',
      caseSensitive: false,
    ).firstMatch(d);
    if (venta != null) {
      return (tipo: 'venta', ref: venta.group(1)!.trim());
    }

    final nc = RegExp(
      r'NC\s+([A-Za-z0-9\-]+)',
      caseSensitive: false,
    ).firstMatch(d);
    if (nc != null) {
      return (tipo: 'nc', ref: nc.group(1)!.trim());
    }

    if (RegExp(r'Ajuste', caseSensitive: false).hasMatch(d)) {
      return (tipo: 'ajuste', ref: d);
    }

    final conteo = RegExp(
      r'CONTEO-(\d+)',
      caseSensitive: false,
    ).firstMatch(d);
    if (conteo != null) {
      return (tipo: 'conteo', ref: conteo.group(1)!);
    }

    return null;
  }

  Future<void> _abrirDocumentoRelacionado(String doc) async {
    final parsed = _parseDocRef(doc);
    if (parsed == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se reconoció el documento: $doc')),
      );
      return;
    }

    try {
      final repo = ref.read(ventasRepositoryProvider);

      if (parsed.tipo == 'factura') {
        var venta = await repo.buscarPorNumeroFactura(parsed.ref);
        venta ??= await repo.buscarPorNumeroCotizacion(parsed.ref);
        if (venta?.id == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se encontró la factura ${parsed.ref}'),
            ),
          );
          return;
        }
        if (!mounted) return;
        await context.push(
          '/ventas/historial/detalle?id=${venta!.id}',
          extra: venta,
        );
        return;
      }

      if (parsed.tipo == 'venta') {
        final asId = int.tryParse(parsed.ref);
        var venta = await repo.buscarPorNumeroCotizacion(parsed.ref);
        if (venta == null && asId != null) {
          venta = await repo.obtenerVentaPorId(asId);
        }
        if (venta?.id == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se encontró la venta ${parsed.ref}'),
            ),
          );
          return;
        }
        if (!mounted) return;
        await context.push(
          '/ventas/historial/detalle?id=${venta!.id}',
          extra: venta,
        );
        return;
      }

      if (parsed.tipo == 'nc') {
        // NC: intentar NCF de NC; si no, el de la factura en el mismo texto
        var venta = await repo.buscarPorNumeroFactura(parsed.ref);
        if (venta == null) {
          final fact = RegExp(
            r'Factura\s+([A-Za-z0-9\-]+)',
            caseSensitive: false,
          ).firstMatch(doc);
          if (fact != null) {
            venta = await repo.buscarPorNumeroFactura(fact.group(1)!.trim());
          }
        }
        if (venta?.id == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se encontró el documento ${parsed.ref}'),
            ),
          );
          return;
        }
        if (!mounted) return;
        await context.push(
          '/ventas/historial/detalle?id=${venta!.id}',
          extra: venta,
        );
        return;
      }

      if (parsed.tipo == 'ajuste') {
        if (!mounted) return;
        await context.push('/lista-ajustes');
        return;
      }

      if (parsed.tipo == 'conteo') {
        if (!mounted) return;
        await context.push('/inventario-fisico/capturar/${parsed.ref}');
        return;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir documento: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pid = _productoIdFijo;
    final movimientosAsync = pid != null
        ? ref.watch(kardexPorProductoProvider(pid))
        : ref.watch(kardexHistorialCompletoProvider);
    final productosAsync = ref.watch(productoControllerProvider);
    final categoriasAsync = ref.watch(categoriaControllerProvider);
    final usuariosFuture = _cargarNombresUsuario();

    return AppScaffold(
      showAppBar: false,
      useAppPage: false,
      backgroundColor: _bgMain,
      body: movimientosAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _teal),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error al cargar movimientos: $e',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        data: (movimientos) {
          final productos = <int, Producto>{};
          for (final p in productosAsync.valueOrNull ?? const <Producto>[]) {
            if (p.id != null) productos[p.id!] = p;
          }
          final categorias = <int, String>{};
          for (final c in categoriasAsync.valueOrNull ?? const <Categoria>[]) {
            if (c.id != null) categorias[c.id!] = c.nombre;
          }

          return FutureBuilder<Map<int, String>>(
            future: usuariosFuture,
            builder: (context, snap) {
              final usuarios = snap.data ?? {};
              final filtrados =
                  _filtrar(movimientos, productos: productos);
              final ahora = DateTime.now();
              final delMes = movimientos.where((m) {
                final f = m.fechaMovimiento;
                return f != null &&
                    f.year == ahora.year &&
                    f.month == ahora.month;
              });
              final saldosPorProducto = <int, double>{};
              for (final m in movimientos) {
                saldosPorProducto[m.productoId] = m.saldoNuevo;
              }
              final stockTotal = saldosPorProducto.values
                  .fold<double>(0, (a, b) => a + b);
              final entradasMes = delMes
                  .where((m) => m.tipoMovimiento == TipoMovimiento.entrada)
                  .fold<double>(0, (a, m) => a + m.cantidad);
              final salidasMes = delMes
                  .where((m) => m.tipoMovimiento == TipoMovimiento.salida)
                  .fold<double>(0, (a, m) => a + m.cantidad);
              final diasInv = salidasMes > 0
                  ? (stockTotal / (salidasMes / 30)).toStringAsFixed(1)
                  : '—';

              final totalPaginas = filtrados.isEmpty
                  ? 1
                  : ((filtrados.length + _porPagina - 1) ~/ _porPagina);
              final paginaActual = _pagina.clamp(1, totalPaginas);
              final inicio = (paginaActual - 1) * _porPagina;
              final paginaItems =
                  filtrados.skip(inicio).take(_porPagina).toList();

              final isMobile = AppBreakpoints.isMobile(context);

              if (isMobile) {
                return _buildMobile(
                  stockTotal: stockTotal,
                  entradasMes: entradasMes,
                  salidasMes: salidasMes,
                  diasInv: diasInv,
                  paginaItems: paginaItems,
                  paginaActual: paginaActual,
                  totalPaginas: totalPaginas,
                  totalFiltrados: filtrados.length,
                  productos: productos,
                  usuarios: usuarios,
                  categorias: categorias,
                  listaCategorias:
                      categoriasAsync.valueOrNull ?? const <Categoria>[],
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.inventory_2_outlined,
                                    color: _textMuted, size: 26),
                                SizedBox(width: 10),
                                Text(
                                  'Kárdex de inventario',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: _textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildKpis(
                              stockTotal: stockTotal,
                              entradasMes: entradasMes,
                              salidasMes: salidasMes,
                              diasInv: diasInv,
                              width: constraints.maxWidth,
                            ),
                            const SizedBox(height: 24),
                            _buildFiltros(
                              listaCategorias: categoriasAsync
                                      .valueOrNull ??
                                  const <Categoria>[],
                            ),
                            const SizedBox(height: 16),
                            _buildTabla(
                              paginaItems,
                              productos: productos,
                              usuarios: usuarios,
                              categorias: categorias,
                            ),
                            const SizedBox(height: 12),
                            _buildPaginacion(
                              paginaActual: paginaActual,
                              totalPaginas: totalPaginas,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ─── MÓVIL ───────────────────────────────────────────────────────────
  Widget _buildMobile({
    required double stockTotal,
    required double entradasMes,
    required double salidasMes,
    required String diasInv,
    required List<Kardex> paginaItems,
    required int paginaActual,
    required int totalPaginas,
    required int totalFiltrados,
    required Map<int, Producto> productos,
    required Map<int, String> usuarios,
    required Map<int, String> categorias,
    required List<Categoria> listaCategorias,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        const Text(
          'Kárdex',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$totalFiltrados movimientos',
          style: const TextStyle(
            fontSize: 13,
            color: _textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _kpiMobile(
                Icons.inventory_2_outlined,
                'Stock',
                _fmtNum(stockTotal),
                const Color(0xFF0F766E),
                const Color(0xFFCCFBF1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiMobile(
                Icons.login_rounded,
                'Entradas mes',
                '+${_fmtNum(entradasMes)}',
                const Color(0xFF16A34A),
                const Color(0xFFDCFCE7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _kpiMobile(
                Icons.logout_rounded,
                'Salidas mes',
                '-${_fmtNum(salidasMes)}',
                const Color(0xFFDC2626),
                const Color(0xFFFEE2E2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiMobile(
                Icons.calendar_month_outlined,
                'Días inv.',
                diasInv == '—' ? '—' : diasInv,
                const Color(0xFF2563EB),
                const Color(0xFFDBEAFE),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (v) => setState(() {
            _filtroBusqueda = v;
            _pagina = 1;
          }),
          decoration: InputDecoration(
            hintText: 'Producto o documento',
            prefixIcon:
                const Icon(Icons.search, size: 20, color: _textMuted),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chipTipo(null, 'Todos'),
              const SizedBox(width: 8),
              _chipTipo(TipoMovimiento.entrada, 'Entrada'),
              const SizedBox(width: 8),
              _chipTipo(TipoMovimiento.salida, 'Salida'),
              const SizedBox(width: 8),
              _chipTipo(TipoMovimiento.ajuste, 'Ajuste'),
              const SizedBox(width: 8),
              ...listaCategorias.where((c) => c.id != null).take(6).map((c) {
                final sel = _filtroCategoriaId == c.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      c.nombre,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    selected: sel,
                    selectedColor: const Color(0xFFE0F2F1),
                    checkmarkColor: _teal,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: sel ? _teal : _border, width: 1.5),
                    onSelected: (_) => setState(() {
                      _filtroCategoriaId = sel ? null : c.id;
                      _pagina = 1;
                    }),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (paginaItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Sin movimientos',
                style: TextStyle(
                  color: _textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        else
          for (final mov in paginaItems) ...[
            _cardMovil(
              mov,
              productos: productos,
              usuarios: usuarios,
              categorias: categorias,
            ),
            const SizedBox(height: 10),
          ],
        if (totalPaginas > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: paginaActual > 1
                    ? () => setState(() => _pagina = paginaActual - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '$paginaActual / $totalPaginas',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
              IconButton(
                onPressed: paginaActual < totalPaginas
                    ? () => setState(() => _pagina = paginaActual + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _kpiMobile(
    IconData icon,
    String label,
    String value,
    Color accent,
    Color soft,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipTipo(TipoMovimiento? tipo, String label) {
    final selected = _filtroTipo == tipo;
    return FilterChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      selected: selected,
      selectedColor: const Color(0xFFE0F2F1),
      checkmarkColor: _teal,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? _teal : _border, width: 1.5),
      onSelected: (_) => setState(() {
        _filtroTipo = tipo;
        _pagina = 1;
      }),
    );
  }

  Widget _cardMovil(
    Kardex mov, {
    required Map<int, Producto> productos,
    required Map<int, String> usuarios,
    required Map<int, String> categorias,
  }) {
    final entrada = _esEntrada(mov.tipoMovimiento);
    final colorTipo =
        entrada ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final bgTipo =
        entrada ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final doc = (mov.documentoReferencia ?? '').trim().isEmpty
        ? 'Sin documento'
        : mov.documentoReferencia!.trim();
    final prod = productos[mov.productoId];
    final nombreProd = prod?.nombre ?? 'Producto #${mov.productoId}';
    final user = usuarios[mov.usuarioId] ?? '#${mov.usuarioId}';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _verDocumento(
          mov,
          productos: productos,
          usuarios: usuarios,
          categorias: categorias,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border, width: 1.5),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: colorTipo,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: bgTipo,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _labelTipo(mov.tipoMovimiento),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: colorTipo,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _fmtFecha(mov.fechaMovimiento),
                              style: const TextStyle(
                                fontSize: 12,
                                color: _textMuted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          doc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$nombreProd · $user',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _miniStat('Cant.', _fmtNum(mov.cantidad)),
                            const SizedBox(width: 12),
                            _miniStat(
                                'Valor', _fmtMoney(mov.totalMovimiento)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: bgTipo,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_fmtNum(mov.saldoAnterior)} → ${_fmtNum(mov.saldoNuevo)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: colorTipo,
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
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: _textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }

  // ─── DESKTOP KPIs ────────────────────────────────────────────────────
  Widget _buildKpis({
    required double stockTotal,
    required double entradasMes,
    required double salidasMes,
    required String diasInv,
    required double width,
  }) {
    final cols = width >= 1024 ? 4 : (width >= 650 ? 2 : 1);
    final items = [
      _kpiCard(
        icon: Icons.inventory_2_outlined,
        titulo: 'Stock Actual Total',
        valor: _fmtNum(stockTotal),
        accent: const Color(0xFF0F766E),
        soft: const Color(0xFFCCFBF1),
        chartColor: const Color(0xFF14B8A6),
      ),
      _kpiCard(
        icon: Icons.login_rounded,
        titulo: 'Movimientos del Mes (Entradas)',
        valor: '+${_fmtNum(entradasMes)}',
        accent: const Color(0xFF16A34A),
        soft: const Color(0xFFDCFCE7),
        chartColor: const Color(0xFF22C55E),
      ),
      _kpiCard(
        icon: Icons.logout_rounded,
        titulo: 'Movimientos del Mes (Salidas)',
        valor: '-${_fmtNum(salidasMes)}',
        accent: const Color(0xFFDC2626),
        soft: const Color(0xFFFEE2E2),
        chartColor: const Color(0xFFEF4444),
      ),
      _kpiCard(
        icon: Icons.calendar_month_outlined,
        titulo: 'Días de Inventario Promedio',
        valor: diasInv == '—' ? '—' : '$diasInv días',
        accent: const Color(0xFF2563EB),
        soft: const Color(0xFFDBEAFE),
        chartColor: const Color(0xFF3B82F6),
      ),
    ];
    if (cols == 1) {
      return Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            items[i],
          ],
        ],
      );
    }
    return Column(
      children: [
        for (var row = 0; row < (items.length / cols).ceil(); row++) ...[
          if (row > 0) const SizedBox(height: 14),
          Row(
            children: [
              for (var c = 0; c < cols; c++) ...[
                if (c > 0) const SizedBox(width: 14),
                Expanded(
                  child: row * cols + c < items.length
                      ? items[row * cols + c]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required String titulo,
    required String valor,
    required Color accent,
    required Color soft,
    required Color chartColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: soft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 18, color: accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: accent.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 72,
            height: 40,
            child: CustomPaint(
              painter: _MiniSparkPainter(color: chartColor),
            ),
          ),
        ],
      ),
    );
  }

  // ─── FILTROS DESKTOP ─────────────────────────────────────────────────
  Widget _buildFiltros({required List<Categoria> listaCategorias}) {
    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _border, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _border, width: 1.5),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1.5),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            child: TextField(
              onChanged: (v) => setState(() {
                _filtroBusqueda = v;
                _pagina = 1;
              }),
              style: const TextStyle(fontWeight: FontWeight.w700),
              decoration: deco('Buscar producto o documento').copyWith(
                prefixIcon:
                    const Icon(Icons.search, color: _textMuted, size: 20),
                labelText: null,
                hintText: 'Buscar producto o documento',
                hintStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(
            width: 140,
            child: InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _filtroFecha ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (d != null) {
                  setState(() {
                    _filtroFecha = d;
                    _pagina = 1;
                  });
                }
              },
              child: InputDecorator(
                decoration: deco('Fecha').copyWith(
                  suffixIcon: const Icon(Icons.calendar_today, size: 16),
                ),
                child: Text(
                  _filtroFecha == null ? '—' : _fmtFecha(_filtroFecha),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 170,
            child: InputDecorator(
              decoration: deco('Tipo de movimiento'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TipoMovimiento?>(
                  isDense: true,
                  isExpanded: true,
                  value: _filtroTipo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                  hint: const Text(
                    'Todos',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ...TipoMovimiento.values.map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(_labelTipo(t)),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    _filtroTipo = v;
                    _pagina = 1;
                  }),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 180,
            child: InputDecorator(
              decoration: deco('Categoría producto'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  isDense: true,
                  isExpanded: true,
                  value: _filtroCategoriaId,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                  hint: const Text(
                    'Todas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todas'),
                    ),
                    ...listaCategorias
                        .where((c) => c.id != null)
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.nombre,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                  ],
                  onChanged: (v) => setState(() {
                    _filtroCategoriaId = v;
                    _pagina = 1;
                  }),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 130,
            child: TextField(
              onChanged: (v) => setState(() {
                _filtroUsuario = v;
                _pagina = 1;
              }),
              style: const TextStyle(fontWeight: FontWeight.w700),
              decoration: deco('Usuario (ID)').copyWith(hintText: 'ID'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TABLA DESKTOP ───────────────────────────────────────────────────
  Widget _buildTabla(
    List<Kardex> items, {
    required Map<int, Producto> productos,
    required Map<int, String> usuarios,
    required Map<int, String> categorias,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1.5),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1080),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  border: Border(
                    bottom: BorderSide(color: _border, width: 1.5),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: _headerChip('TIPO', const Color(0xFF14B8A6)),
                    ),
                    SizedBox(
                      width: 280,
                      child:
                          _headerChip('DOC / PRODUCTO', const Color(0xFF818CF8)),
                    ),
                    SizedBox(
                      width: 140,
                      child: _headerChip('USUARIO', const Color(0xFF64748B)),
                    ),
                    SizedBox(
                      width: 70,
                      child: _headerChip('CANT.', const Color(0xFFF59E0B)),
                    ),
                    SizedBox(
                      width: 100,
                      child:
                          _headerChip('VALOR TOTAL', const Color(0xFF64748B)),
                    ),
                    SizedBox(
                      width: 120,
                      child:
                          _headerChip('SALDO (UNIT)', const Color(0xFF22C55E)),
                    ),
                    SizedBox(
                      width: 95,
                      child: _headerChip('FECHA', const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Text(
                    'No hay movimientos registrados o coincidentes.',
                    style: TextStyle(
                      color: _textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                for (final mov in items)
                  _fila(
                    mov,
                    productos: productos,
                    usuarios: usuarios,
                    categorias: categorias,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fila(
    Kardex mov, {
    required Map<int, Producto> productos,
    required Map<int, String> usuarios,
    required Map<int, String> categorias,
  }) {
    final entrada = _esEntrada(mov.tipoMovimiento);
    final colorTipo =
        entrada ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final bgTipo =
        entrada ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final doc = (mov.documentoReferencia ?? '').trim().isEmpty
        ? 'Sin documento'
        : mov.documentoReferencia!.trim();
    final prod = productos[mov.productoId];
    final nombreProd = prod?.nombre ?? 'Producto #${mov.productoId}';
    final user = usuarios[mov.usuarioId] ?? 'Usuario #${mov.usuarioId}';

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _verDocumento(
          mov,
          productos: productos,
          usuarios: usuarios,
          categorias: categorias,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _border)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 34,
                      decoration: BoxDecoration(
                        color: colorTipo,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: bgTipo,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _labelTipo(mov.tipoMovimiento),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: colorTipo,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 280,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _bgMain,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _border, width: 1.5),
                      ),
                      child: Icon(
                        entrada
                            ? Icons.storefront_outlined
                            : Icons.receipt_long_outlined,
                        size: 18,
                        color: _textMuted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            nombreProd,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 140,
                child: Text(
                  user,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  _fmtNum(mov.cantidad),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  _fmtMoney(mov.totalMovimiento),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgTipo,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_fmtNum(mov.saldoAnterior)} → ${_fmtNum(mov.saldoNuevo)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: colorTipo,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 95,
                child: Text(
                  _fmtFecha(mov.fechaMovimiento),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(
                width: 48,
                child: IconButton(
                  tooltip: 'Ver documento',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 20,
                    color: _teal,
                  ),
                  onPressed: () => _verDocumento(
                    mov,
                    productos: productos,
                    usuarios: usuarios,
                    categorias: categorias,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPaginacion({
    required int paginaActual,
    required int totalPaginas,
  }) {
    return Row(
      children: [
        Text(
          'Página $paginaActual de $totalPaginas',
          style: const TextStyle(
            fontSize: 13,
            color: _textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed:
              paginaActual > 1 ? () => setState(() => _pagina = 1) : null,
          icon: const Icon(Icons.keyboard_double_arrow_left),
          iconSize: 20,
        ),
        IconButton(
          onPressed: paginaActual > 1
              ? () => setState(() => _pagina = paginaActual - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
          iconSize: 20,
        ),
        for (var n = 1; n <= totalPaginas && n <= 5; n++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: n == paginaActual ? _teal : Colors.white,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: () => setState(() => _pagina = n),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: n == paginaActual ? _teal : _border,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '$n',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: n == paginaActual ? Colors.white : _textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (totalPaginas > 5)
          TextButton(
            onPressed: () => setState(() => _pagina = totalPaginas),
            child: Text(
              '$totalPaginas',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        IconButton(
          onPressed: paginaActual < totalPaginas
              ? () => setState(() => _pagina = paginaActual + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
          iconSize: 20,
        ),
        IconButton(
          onPressed: paginaActual < totalPaginas
              ? () => setState(() => _pagina = totalPaginas)
              : null,
          icon: const Icon(Icons.keyboard_double_arrow_right),
          iconSize: 20,
        ),
        const SizedBox(width: 12),
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _porPagina,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
            items: const [
              DropdownMenuItem(value: 10, child: Text('10 / pág')),
              DropdownMenuItem(value: 15, child: Text('15 / pág')),
              DropdownMenuItem(value: 25, child: Text('25 / pág')),
              DropdownMenuItem(value: 50, child: Text('50 / pág')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _porPagina = v;
                _pagina = 1;
              });
            },
          ),
        ),
      ],
    );
  }
}

class _MiniSparkPainter extends CustomPainter {
  _MiniSparkPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    final pts = [0.15, 0.55, 0.35, 0.7, 0.55, 0.4, 0.75, 0.65, 0.95, 0.25];
    for (var i = 0; i < pts.length; i += 2) {
      final x = pts[i] * size.width;
      final y = pts[i + 1] * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
