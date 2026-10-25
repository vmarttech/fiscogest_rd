import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/core/navigation/safe_back.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_action_bar.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/reportes/presentation/providers/dashboard_providers.dart';

/// Detalle de un reporte operativo o DGII por rango de fechas.
class DetalleReportePage extends ConsumerStatefulWidget {
  const DetalleReportePage({super.key, required this.tipo});

  /// ventas | compras | utilidades | productos | clientes | proveedores | 606 | 607
  final String tipo;

  static const String routeName = 'detalle-reporte';

  @override
  ConsumerState<DetalleReportePage> createState() => _DetalleReportePageState();
}

class _DetalleReportePageState extends ConsumerState<DetalleReportePage> {
  late DateTime _desde;
  late DateTime _hasta;
  bool _cargando = false;
  String? _error;
  Map<String, dynamic>? _data;
  String _busqueda = '';
  final _busquedaCtrl = TextEditingController();

  final _fmtFecha = DateFormat('dd/MM/yyyy');
  final _fmtFechaHora = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _desde = DateTime(now.year, now.month, 1);
    _hasta = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    WidgetsBinding.instance.addPostFrameCallback((_) => _generar());
  }

  String get _titulo {
    return switch (widget.tipo) {
      'ventas' => 'Reporte de ventas',
      'compras' => 'Reporte de compras',
      'utilidades' => 'Utilidades y margen',
      'productos' => 'Productos más vendidos',
      'clientes' => 'Ventas por cliente',
      'proveedores' => 'Compras por proveedor',
      '606' => '606 · Compras DGII',
      '607' => '607 · Ventas DGII',
      _ => 'Reporte',
    };
  }

  Future<void> _pickDesde() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _desde,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      ),
    );
    if (d != null) {
      setState(() => _desde = DateTime(d.year, d.month, d.day));
    }
  }

  Future<void> _pickHasta() async {
    final base = _hasta.subtract(const Duration(days: 1));
    final d = await showDatePicker(
      context: context,
      initialDate: base.isBefore(_desde) ? _desde : base,
      firstDate: _desde,
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      ),
    );
    if (d != null) {
      setState(
        () => _hasta = DateTime(d.year, d.month, d.day).add(const Duration(days: 1)),
      );
    }
  }

  Future<void> _generar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final repo = ref.read(reportesRepositoryProvider);
      final data = await repo.generarPorTipo(widget.tipo, _desde, _hasta);
      if (!mounted) return;
      setState(() {
        _data = data;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _cargando = false;
        _data = null;
      });
    }
  }


  List<Map<String, dynamic>> get _regsFiltrados {
    final regs = (_data?['registros'] as List?)?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];
    final q = _busqueda.trim().toLowerCase();
    if (q.isEmpty) return regs;
    return regs.where((row) {
      final vals = _valoresFila(row);
      return vals.any((c) => c.toLowerCase().contains(q));
    }).toList();
  }

  String _fmtCell(dynamic v) {
    if (v == null) return '—';
    if (v is num && (v >= 100 || v.toString().contains('.'))) {
      // montos típicos
      if (v is double || (v is int && v > 50)) {
        // heurística: si es total-like
      }
    }
    if (v is double) return formatRd(v);
    if (v is int) return v.toString();
    final s = v.toString();
    // fechas ISO
    if (s.length >= 10 && s.contains('T')) {
      try {
        return _fmtFechaHora.format(DateTime.parse(s));
      } catch (_) {}
    }
    if (s.length >= 10 && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) {
      try {
        return _fmtFecha.format(DateTime.parse(s.substring(0, 10)));
      } catch (_) {}
    }
    return s;
  }

  List<String> _valoresFila(Map<String, dynamic> row) {
    return switch (widget.tipo) {
      'ventas' || '607' => [
          _fmtCell(row['fecha']),
          row['cliente']?.toString() ?? '',
          row['documento']?.toString() ?? '',
          formatRd((row['total'] as num?)?.toDouble() ?? 0),
          widget.tipo == '607'
              ? formatRd((row['itbis'] as num?)?.toDouble() ?? 0)
              : (row['formaPago']?.toString() ?? ''),
        ],
      'compras' || '606' => [
          _fmtCell(row['fecha']),
          row['proveedor']?.toString() ?? '',
          widget.tipo == '606'
              ? (row['ncf']?.toString() ?? '')
              : (row['documento']?.toString() ?? ''),
          widget.tipo == '606'
              ? formatRd((row['total'] as num?)?.toDouble() ?? 0)
              : (row['ncf']?.toString() ?? ''),
          widget.tipo == '606'
              ? formatRd((row['itbis'] as num?)?.toDouble() ?? 0)
              : formatRd((row['total'] as num?)?.toDouble() ?? 0),
        ],
      'utilidades' || 'productos' => [
          row['nombre']?.toString() ?? '',
          ((row['cantidad'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
          formatRd((row['monto'] as num?)?.toDouble() ?? 0),
        ],
      'clientes' => [
          row['cliente']?.toString() ?? '',
          '${row['facturas'] ?? 0}',
          formatRd((row['total'] as num?)?.toDouble() ?? 0),
        ],
      'proveedores' => [
          row['proveedor']?.toString() ?? '',
          '${row['compras'] ?? 0}',
          formatRd((row['total'] as num?)?.toDouble() ?? 0),
        ],
      _ => row.values.map(_fmtCell).toList(),
    };
  }


  List<List<String>> _filasExport() {
    final cols = (_data?['columnas'] as List?)?.cast<String>() ?? <String>[];
    final regs = _regsFiltrados;
    final out = <List<String>>[cols];
    for (final r in regs) {
      out.add(_valoresFila(r));
    }
    return out;
  }

  Future<void> _guardarArchivo(String name, List<int> bytes, String mime) async {
    final dir = await getDownloadsDirectory() ?? await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    if (!mounted) return;
    FiscoGestNotifications.show(
      SnackBar(content: Text('Guardado: ${file.path}')),
    );
    if (Platform.isLinux) {
      try { await Process.run('xdg-open', [file.path]); } catch (_) {}
    } else if (Platform.isWindows) {
      try { await Process.run('cmd', ['/c', 'start', '', file.path]); } catch (_) {}
    } else if (Platform.isMacOS) {
      try { await Process.run('open', [file.path]); } catch (_) {}
    } else {
      try {
        await Share.shareXFiles([XFile(file.path, mimeType: mime, name: name)]);
      } catch (_) {}
    }
  }

  Future<void> _exportarCsv() async {
    if (_data == null) return;
    try {
      final filas = _filasExport();
      final buf = StringBuffer();
      for (final f in filas) {
        buf.writeln(f.map((c) {
          final s = c.replaceAll('"', '""');
          return '"$s"';
        }).join(','));
      }
      final name =
          'reporte_${widget.tipo}_${DateTime.now().millisecondsSinceEpoch}.csv';
      await _guardarArchivo(name, buf.toString().codeUnits, 'text/csv');
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(content: Text('Error CSV: $e')),
      );
    }
  }

  Future<void> _exportarPdf() async {
    if (_data == null) return;
    try {
      final filas = _filasExport();
      final total = (_data!['total'] as num?)?.toDouble() ?? 0;
      final cant = (_data!['cantidad'] as num?)?.toInt() ?? 0;
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (ctx) => [
            pw.Text(
              _titulo,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Periodo: ${_fmtFecha.format(_desde)} — ${_fmtFecha.format(_hasta.subtract(const Duration(days: 1)))}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Registros: $cant   ·   Total: ${formatRd(total)}',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            if (filas.isNotEmpty)
              pw.TableHelper.fromTextArray(
                headers: filas.first,
                data: filas.length > 1 ? filas.sublist(1) : <List<String>>[],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerLeft,
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
              ),
          ],
        ),
      );
      final bytes = await doc.save();
      final name =
          'reporte_${widget.tipo}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await _guardarArchivo(name, bytes, 'application/pdf');
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('Error PDF: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final cols = (_data?['columnas'] as List?)?.cast<String>() ?? <String>[];
    final regs = _regsFiltrados;

    return AppScaffold(
      title: _titulo.toUpperCase(),
      showAppBar: false,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: mobile ? 720 : 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Solo ← + título (SIN barra teal)
                Padding(
                  padding: EdgeInsets.fromLTRB(mobile ? 8 : 16, 8, mobile ? 16 : 24, 8),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Atrás',
                        onPressed: () =>
                            safeBack(context, fallback: '/reports/hub'),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _titulo.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '${_fmtFecha.format(_desde)} — ${_fmtFecha.format(_hasta.subtract(const Duration(days: 1)))}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    mobile ? 16 : 24,
                    0,
                    mobile ? 16 : 24,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppActionBar(
                        alignment: WrapAlignment.start,
                        actions: [
                          OutlinedButton.icon(
                            onPressed: _cargando ? null : _pickDesde,
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              'Desde ${_fmtFecha.format(_desde)}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _cargando ? null : _pickHasta,
                            icon: const Icon(Icons.event, size: 16),
                            label: Text(
                              'Hasta ${_fmtFecha.format(_hasta.subtract(const Duration(days: 1)))}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: mobile ? double.infinity : 220,
                          child: ElevatedButton.icon(
                            onPressed: _cargando ? null : _generar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00796B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: _cargando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.play_arrow_rounded),
                            label: Text(
                              _cargando ? 'Generando…' : 'Generar reporte',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                      if (_data != null) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _cargando ? null : _exportarCsv,
                              icon: const Icon(Icons.table_view_outlined, size: 18),
                              label: const Text(
                                'CSV',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _cargando ? null : _exportarPdf,
                              icon: const Icon(
                                Icons.picture_as_pdf_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                'PDF',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _busquedaCtrl,
                          onChanged: (v) => setState(() => _busqueda = v),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          decoration: InputDecoration(
                            hintText: 'Buscar en resultados…',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _busqueda.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _busquedaCtrl.clear();
                                      setState(() => _busqueda = '');
                                    },
                                  ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                if (_data != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      mobile ? 16 : 24,
                      16,
                      mobile ? 16 : 24,
                      8,
                    ),
                    child: _ResumenCards(data: _data!, tipo: widget.tipo),
                  ),
                Expanded(
                  child: _cargando && _data == null
                      ? const Center(child: CircularProgressIndicator())
                      : regs.isEmpty
                          ? Center(
                              child: Text(
                                'Sin movimientos en el período',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : mobile
                              ? ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                  itemCount: regs.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (_, i) {
                                    final row =
                                        Map<String, dynamic>.from(regs[i]);
                                    final vals = _valoresFila(row);
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          for (var c = 0;
                                              c < cols.length && c < vals.length;
                                              c++)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 4,
                                              ),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 100,
                                                    child: Text(
                                                      cols[c],
                                                      style: AppTypography
                                                          .labelSmall
                                                          .copyWith(
                                                        color: AppColors
                                                            .textSecondary,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      vals[c],
                                                      style: AppTypography
                                                          .bodySmall
                                                          .copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    8,
                                    24,
                                    24,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: SingleChildScrollView(
                                        scrollDirection: Axis.vertical,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: DataTable(
                                            headingRowColor:
                                                WidgetStatePropertyAll(
                                              const Color(0xFF00796B)
                                                  .withValues(alpha: 0.08),
                                            ),
                                            columns: [
                                              for (final c in cols)
                                                DataColumn(
                                                  label: Text(
                                                    c,
                                                    style: AppTypography
                                                        .labelSmall
                                                        .copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                            rows: [
                                              for (final r in regs)
                                                DataRow(
                                                  cells: [
                                                    for (final v
                                                        in _valoresFila(
                                                      Map<String, dynamic>.from(
                                                        r,
                                                      ),
                                                    ))
                                                      DataCell(
                                                        Text(
                                                          v,
                                                          style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
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
}


class _ResumenCards extends StatelessWidget {
  const _ResumenCards({required this.data, required this.tipo});
  final Map<String, dynamic> data;
  final String tipo;

  @override
  Widget build(BuildContext context) {
    final total = (data['total'] as num?)?.toDouble() ?? 0;
    final cant = (data['cantidad'] as num?)?.toInt() ?? 0;
    final ganancia = (data['ganancia'] as num?)?.toDouble();
    final gastos = (data['gastos'] as num?)?.toDouble();
    final gananciaNeta = (data['gananciaNeta'] as num?)?.toDouble();
    final itbis = (data['itbis'] as num?)?.toDouble();

    final items = <(String, String, Color)>[
      ('Registros', '$cant', AppColors.primary),
      ('Total', formatRd(total), AppColors.success),
      if (ganancia != null) ('G. bruta', formatRd(ganancia), AppColors.warning),
      if (gastos != null) ('Gastos', formatRd(gastos), AppColors.error),
      if (gananciaNeta != null)
        ('G. neta', formatRd(gananciaNeta), const Color(0xFF0EA5E9)),
      if (itbis != null) ('ITBIS', formatRd(itbis), AppColors.info),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final mobile = c.maxWidth < 600;
        Container card(int i) => Container(
              width: mobile ? (c.maxWidth - 10) / 2 : null,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: items[i].$3.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: items[i].$3.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    items[i].$1,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: items[i].$3,
                    ),
                  ),
                ],
              ),
            );

        if (mobile) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [for (var i = 0; i < items.length; i++) card(i)],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: card(i)),
            ],
          ],
        );
      },
    );
  }
}


