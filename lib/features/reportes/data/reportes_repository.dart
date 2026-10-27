import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/reportes/domain/kpi_models.dart';
import 'package:intl/intl.dart';

/// Agregados de ventas cobradas (facturado + enCredito).
class ReportesRepository {
  ReportesRepository(this._db);
  String _fmtFechaRepo(dynamic raw) {
    if (raw == null) return '';
    if (raw is DateTime) {
      return '${raw.day.toString().padLeft(2, '0')}/${raw.month.toString().padLeft(2, '0')}/${raw.year}';
    }
    if (raw is num) {
      var n = raw.toInt();
      if (n > 1000000000 && n < 100000000000) n *= 1000;
      if (n > 100000000000) {
        final d = DateTime.fromMillisecondsSinceEpoch(n);
        return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      }
    }
    final s = raw.toString();
    try {
      final d = DateTime.parse(s);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return s;
    }
  }

  final AppDatabase _db;

  static const _estadosVenta = "('facturado','enCredito')";

  Future<DashboardSnapshot> cargarDashboard() async {
    final now = DateTime.now();
    final inicioHoy = DateTime(now.year, now.month, now.day);
    final finHoy = inicioHoy.add(const Duration(days: 1));
    final inicioSem = inicioHoy.subtract(Duration(days: now.weekday - 1));
    final inicioMes = DateTime(now.year, now.month, 1);
    final inicioAnio = DateTime(now.year, 1, 1);

    final hoy = await _kpiRango(
      inicioHoy,
      finHoy,
      inicioHoy.subtract(const Duration(days: 1)),
      inicioHoy,
    );
    final semana = await _kpiRango(
      inicioSem,
      finHoy,
      inicioSem.subtract(const Duration(days: 7)),
      inicioSem,
    );
    final mes = await _kpiRango(
      inicioMes,
      finHoy,
      DateTime(now.year, now.month - 1, 1),
      inicioMes,
    );
    final anio = await _kpiRango(
      inicioAnio,
      finHoy,
      DateTime(now.year - 1, 1, 1),
      inicioAnio,
    );

    final serie = await _serieDiaria(
      inicioHoy.subtract(const Duration(days: 29)),
      finHoy,
    );
    final pagos = await _porFormaPago(inicioMes, finHoy);
    final top = await _topProductos(inicioMes, finHoy, 5);

    return DashboardSnapshot(
      hoy: hoy,
      semana: semana,
      mes: mes,
      anio: anio,
      serie30Dias: serie,
      porFormaPago: pagos,
      topProductos: top,
    );
  }

  Future<KpiPeriodo> _kpiRango(
    DateTime desde,
    DateTime hasta,
    DateTime desdeAnt,
    DateTime hastaAnt,
  ) async {
    final actual = await _agregado(desde, hasta);
    final ant = await _agregado(desdeAnt, hastaAnt);
    final gastos = await _sumGastos(desde, hasta);
    final gastosAnt = await _sumGastos(desdeAnt, hastaAnt);
    return KpiPeriodo(
      ventas: actual.$1,
      numFacturas: actual.$2,
      ganancia: actual.$3,
      ventasAnterior: ant.$1,
      gananciaAnterior: ant.$3,
      gastos: gastos,
      gastosAnterior: gastosAnt,
    );
  }

  Future<double> _sumGastos(DateTime desde, DateTime hasta) async {
    try {
      final rows = await _db
          .customSelect(
            '''
        SELECT COALESCE(SUM(monto), 0.0) AS total
        FROM gastos_table
        WHERE fecha >= ? AND fecha < ?
        ''',
            variables: [
              Variable.withDateTime(desde),
              Variable.withDateTime(hasta),
            ],
            readsFrom: {_db.gastosTable},
          )
          .get();
      if (rows.isEmpty) return 0.0;
      return (rows.first.data['total'] as num?)?.toDouble() ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  /// (ventas, num, ganancia)
  Future<(double, int, double)> _agregado(
    DateTime desde,
    DateTime hasta,
  ) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT
        COALESCE(SUM(v.monto_total), 0.0) AS ventas,
        COUNT(*) AS n,
        COALESCE(SUM(
          (SELECT COALESCE(SUM(
             d.cantidad * COALESCE(p.precio_compra, 0.0)
           ), 0.0)
           FROM ventas_detalle_table d
           LEFT JOIN productos_table p ON p.id = d.producto_id
           WHERE d.venta_id = v.id)
        ), 0.0) AS costo
      FROM ventas_table v
      WHERE v.fecha >= ? AND v.fecha < ?
        AND v.estado_documento IN $_estadosVenta
      ''',
          variables: [
            Variable.withDateTime(desde),
            Variable.withDateTime(hasta),
          ],
          readsFrom: {
            _db.ventasTable,
            _db.ventasDetalleTable,
            _db.productosTable,
          },
        )
        .get();

    if (rows.isEmpty) return (0.0, 0, 0.0);
    final r = rows.first;
    final ventas = (r.data['ventas'] as num?)?.toDouble() ?? 0.0;
    final n = (r.data['n'] as num?)?.toInt() ?? 0;
    final costo = (r.data['costo'] as num?)?.toDouble() ?? 0.0;
    return (ventas, n, ventas - costo);
  }

  Future<List<SeriePunto>> _serieDiaria(DateTime desde, DateTime hasta) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT date(v.fecha, 'unixepoch') AS dia,
             COALESCE(SUM(v.monto_total), 0.0) AS total
      FROM ventas_table v
      WHERE v.fecha >= ? AND v.fecha < ?
        AND v.estado_documento IN $_estadosVenta
      GROUP BY date(v.fecha, 'unixepoch')
      ORDER BY dia
      ''',
          variables: [
            Variable.withDateTime(desde),
            Variable.withDateTime(hasta),
          ],
          readsFrom: {_db.ventasTable},
        )
        .get();

    final map = <String, double>{};
    for (final r in rows) {
      final dia = r.data['dia']?.toString() ?? '';
      map[dia] = (r.data['total'] as num?)?.toDouble() ?? 0.0;
    }

    final out = <SeriePunto>[];
    final fmt = DateFormat('d/M');
    for (var i = 0; i < 30; i++) {
      final d = DateTime(
        desde.year,
        desde.month,
        desde.day,
      ).add(Duration(days: i));
      if (d.isAfter(hasta) || d.isAtSameMomentAs(hasta)) break;
      final key =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      out.add(SeriePunto(fmt.format(d), map[key] ?? 0.0, fecha: d));
    }
    return out;
  }

  Future<Map<String, double>> _porFormaPago(
    DateTime desde,
    DateTime hasta,
  ) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT COALESCE(v.forma_pago, 'Otro') AS fp,
             COALESCE(SUM(v.monto_total), 0.0) AS total
      FROM ventas_table v
      WHERE v.fecha >= ? AND v.fecha < ?
        AND v.estado_documento IN $_estadosVenta
      GROUP BY fp
      ORDER BY total DESC
      ''',
          variables: [
            Variable.withDateTime(desde),
            Variable.withDateTime(hasta),
          ],
          readsFrom: {_db.ventasTable},
        )
        .get();

    final m = <String, double>{};
    for (final r in rows) {
      m[r.data['fp']?.toString() ?? 'Otro'] =
          (r.data['total'] as num?)?.toDouble() ?? 0.0;
    }
    return m;
  }

  Future<List<TopProducto>> _topProductos(
    DateTime desde,
    DateTime hasta,
    int limit,
  ) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT COALESCE(
               NULLIF(TRIM(p.nombre), ''),
               'Producto #' || CAST(d.producto_id AS TEXT)
             ) AS nombre,
             COALESCE(SUM(d.cantidad), 0.0) AS cant,
             COALESCE(SUM(
               CASE
                 WHEN d.subtotal IS NOT NULL AND d.subtotal > 0 THEN d.subtotal
                 ELSE d.cantidad * d.precio_unitario
               END
             ), 0.0) AS monto
      FROM ventas_detalle_table d
      INNER JOIN ventas_table v ON v.id = d.venta_id
      LEFT JOIN productos_table p ON p.id = d.producto_id
      WHERE v.fecha >= ? AND v.fecha < ?
        AND v.estado_documento IN $_estadosVenta
        AND d.producto_id IS NOT NULL
        AND d.producto_id > 0
      GROUP BY d.producto_id
      HAVING monto > 0
      ORDER BY monto DESC
      LIMIT ?
      ''',
          variables: [
            Variable.withDateTime(desde),
            Variable.withDateTime(hasta),
            Variable.withInt(limit),
          ],
          readsFrom: {
            _db.ventasTable,
            _db.ventasDetalleTable,
            _db.productosTable,
          },
        )
        .get();

    return rows
        .map(
          (r) => TopProducto(
            nombre: r.data['nombre']?.toString() ?? 'Producto',
            cantidad: (r.data['cant'] as num?)?.toDouble() ?? 0.0,
            monto: (r.data['monto'] as num?)?.toDouble() ?? 0.0,
          ),
        )
        .toList();
  }

  Future<Map<String, dynamic>> reporteVentas(
    DateTime desde,
    DateTime hasta,
  ) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT v.id, v.fecha, v.nombre_cliente, v.numero_factura, v.numero_cotizacion,
             v.monto_total, v.itbis, v.monto_subtotal, v.forma_pago, v.estado_documento
      FROM ventas_table v
      WHERE v.fecha >= ? AND v.fecha < ?
        AND v.estado_documento IN $_estadosVenta
      ORDER BY v.fecha DESC
      ''',
          variables: [
            Variable.withDateTime(desde),
            Variable.withDateTime(hasta),
          ],
          readsFrom: {_db.ventasTable},
        )
        .get();

    double total = 0, itbis = 0;
    final registros = <Map<String, dynamic>>[];
    final seenIds = <int>{};
    final seenDoc = <String>{};
    for (final r in rows) {
      final id = (r.data['id'] as num?)?.toInt();
      if (id != null && !seenIds.add(id)) continue;
      final m = (r.data['monto_total'] as num?)?.toDouble() ?? 0.0;
      final i = (r.data['itbis'] as num?)?.toDouble() ?? 0.0;
      final ncf = (r.data['numero_factura']?.toString() ?? '').trim();
      final cot = (r.data['numero_cotizacion']?.toString() ?? '').trim();
      final doc = ncf.isNotEmpty ? ncf : cot;
      final key = '$doc|$m|${r.data['fecha']}';
      if (doc.isNotEmpty && !seenDoc.add(key)) continue;
      total += m;
      itbis += i;
      registros.add({
        'id': r.data['id'],
        'fecha': _fmtFechaRepo(r.data['fecha']),
        'cliente': r.data['nombre_cliente']?.toString() ?? 'Consumidor Final',
        'documento': doc,
        'total': m,
        'itbis': i,
        'formaPago': r.data['forma_pago']?.toString() ?? '',
        'estado': r.data['estado_documento']?.toString() ?? '',
      });
    }
    return {
      'titulo': 'Ventas',
      'total': total,
      'itbis': itbis,
      'cantidad': registros.length,
      'registros': registros,
      'columnas': ['Fecha', 'Cliente', 'Documento', 'Total', 'Forma pago'],
    };
  }

  Future<Map<String, dynamic>> reporteCompras(
    DateTime desde,
    DateTime hasta,
  ) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT c.id, c.fecha_emision, c.nombre_proveedor, c.numero_comprobante, c.ncf,
             c.total_compra, c.monto_impuesto, c.forma_pago, c.estado
      FROM compras_table c
      WHERE c.fecha_emision >= ? AND c.fecha_emision < ?
        AND lower(c.estado) NOT IN ('borrador','anulada','anulado')
      ORDER BY c.fecha_emision DESC
      ''',
          variables: [
            Variable.withDateTime(desde),
            Variable.withDateTime(hasta),
          ],
          readsFrom: {_db.comprasTable},
        )
        .get();

    double total = 0, itbis = 0;
    final registros = <Map<String, dynamic>>[];
    final seenIds = <int>{};
    for (final r in rows) {
      final id = (r.data['id'] as num?)?.toInt();
      if (id != null && !seenIds.add(id)) continue;
      final m = (r.data['total_compra'] as num?)?.toDouble() ?? 0.0;
      final i = (r.data['monto_impuesto'] as num?)?.toDouble() ?? 0.0;
      total += m;
      itbis += i;
      registros.add({
        'id': r.data['id'],
        'fecha': _fmtFechaRepo(r.data['fecha_emision']),
        'proveedor': r.data['nombre_proveedor']?.toString() ?? '',
        'documento': r.data['numero_comprobante']?.toString() ?? '',
        'ncf': r.data['ncf']?.toString() ?? '',
        'total': m,
        'itbis': i,
        'formaPago': r.data['forma_pago']?.toString() ?? '',
        'estado': r.data['estado']?.toString() ?? '',
      });
    }
    return {
      'titulo': 'Compras',
      'total': total,
      'itbis': itbis,
      'cantidad': registros.length,
      'registros': registros,
      'columnas': ['Fecha', 'Proveedor', 'Comprobante', 'NCF', 'Total'],
    };
  }

  Future<Map<String, dynamic>> reporteUtilidades(
    DateTime desde,
    DateTime hasta,
  ) async {
    final actual = await _agregado(desde, hasta);
    final gastos = await _sumGastos(desde, hasta);
    final top = await _topProductos(desde, hasta, 100);
    final gananciaBruta = actual.$3;
    final gananciaNeta = gananciaBruta - gastos;
    final listaGastos = await _listarGastosResumen(desde, hasta);
    return {
      'titulo': 'Utilidades',
      'total': actual.$1,
      'ganancia': gananciaBruta,
      'gastos': gastos,
      'gananciaNeta': gananciaNeta,
      'costo': actual.$1 - gananciaBruta,
      'numFacturas': actual.$2,

      'margenPct': actual.$1 <= 0 ? 0.0 : (gananciaBruta / actual.$1) * 100,
      'margenNetoPct': actual.$1 <= 0 ? 0.0 : (gananciaNeta / actual.$1) * 100,
      'registros': () {
        final regs = <Map<String, dynamic>>[
          ...top.map(
            (p) => {
              'nombre': p.nombre,
              'cantidad': p.cantidad,
              'monto': p.monto,
              'tipo': 'producto',
            },
          ),
          ...listaGastos,
        ];
        return regs;
      }(),
      'cantidad': top.length + listaGastos.length,
      'columnas': ['Concepto', 'Cant./Cat.', 'Monto'],
    };
  }

  Future<List<Map<String, dynamic>>> _listarGastosResumen(
    DateTime desde,
    DateTime hasta,
  ) async {
    try {
      final rows = await _db
          .customSelect(
            '''
        SELECT categoria,
               COUNT(*) AS cant,
               COALESCE(SUM(monto), 0.0) AS monto
        FROM gastos_table
        WHERE fecha >= ? AND fecha < ?
        GROUP BY categoria
        ORDER BY monto DESC
        ''',
            variables: [
              Variable.withDateTime(desde),
              Variable.withDateTime(hasta),
            ],
            readsFrom: {_db.gastosTable},
          )
          .get();
      return rows
          .map(
            (r) => {
              'nombre': 'Gasto · ${r.data['categoria'] ?? 'General'}',
              'cantidad': (r.data['cant'] as num?)?.toDouble() ?? 0,
              'monto': (r.data['monto'] as num?)?.toDouble() ?? 0,
              'tipo': 'gasto',
            },
          )
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<Map<String, dynamic>> reporteProductos(
    DateTime desde,
    DateTime hasta,
  ) async {
    final top = await _topProductos(desde, hasta, 200);
    double total = 0;
    for (final p in top) {
      total += p.monto;
    }
    return {
      'titulo': 'Productos',
      'total': total,
      'cantidad': top.length,
      'registros': top
          .map(
            (p) => {
              'nombre': p.nombre,
              'cantidad': p.cantidad,
              'monto': p.monto,
            },
          )
          .toList(),
      'columnas': ['Producto', 'Cant. vendida', 'Monto'],
    };
  }

  Future<Map<String, dynamic>> reporteClientes(
    DateTime desde,
    DateTime hasta,
  ) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT COALESCE(v.nombre_cliente, 'Consumidor Final') AS cliente,
             COUNT(*) AS facturas,
             COALESCE(SUM(v.monto_total), 0.0) AS total
      FROM ventas_table v
      WHERE v.fecha >= ? AND v.fecha < ?
        AND v.estado_documento IN $_estadosVenta
      GROUP BY COALESCE(v.nombre_cliente, 'Consumidor Final')
      ORDER BY total DESC
      LIMIT 100
      ''',
          variables: [
            Variable.withDateTime(desde),
            Variable.withDateTime(hasta),
          ],
          readsFrom: {_db.ventasTable},
        )
        .get();

    double total = 0;
    final registros = <Map<String, dynamic>>[];
    for (final r in rows) {
      final m = (r.data['total'] as num?)?.toDouble() ?? 0.0;
      total += m;
      registros.add({
        'cliente': r.data['cliente']?.toString() ?? '',
        'facturas': (r.data['facturas'] as num?)?.toInt() ?? 0,
        'total': m,
      });
    }
    return {
      'titulo': 'Clientes',
      'total': total,
      'cantidad': registros.length,
      'registros': registros,
      'columnas': ['Cliente', 'Facturas', 'Total'],
    };
  }

  Future<Map<String, dynamic>> reporteProveedores(
    DateTime desde,
    DateTime hasta,
  ) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT COALESCE(c.nombre_proveedor, 'Proveedor') AS proveedor,
             COUNT(*) AS compras,
             COALESCE(SUM(c.total_compra), 0.0) AS total
      FROM compras_table c
      WHERE c.fecha_emision >= ? AND c.fecha_emision < ?
        AND lower(c.estado) NOT IN ('borrador','anulada','anulado')
      GROUP BY COALESCE(c.nombre_proveedor, 'Proveedor')
      ORDER BY total DESC
      LIMIT 100
      ''',
          variables: [
            Variable.withDateTime(desde),
            Variable.withDateTime(hasta),
          ],
          readsFrom: {_db.comprasTable},
        )
        .get();

    double total = 0;
    final registros = <Map<String, dynamic>>[];
    for (final r in rows) {
      final m = (r.data['total'] as num?)?.toDouble() ?? 0.0;
      total += m;
      registros.add({
        'proveedor': r.data['proveedor']?.toString() ?? '',
        'compras': (r.data['compras'] as num?)?.toInt() ?? 0,
        'total': m,
      });
    }
    return {
      'titulo': 'Proveedores',
      'total': total,
      'cantidad': registros.length,
      'registros': registros,
      'columnas': ['Proveedor', 'Compras', 'Total'],
    };
  }

  Future<Map<String, dynamic>> reporte607(
    DateTime desde,
    DateTime hasta,
  ) async {
    final base = await reporteVentas(desde, hasta);
    final regs =
        (base['registros'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    // 607 DGII: solo documentos con NCF / factura (no cotizaciones vacías)
    final filtrados = regs.where((r) {
      final doc = (r['documento']?.toString() ?? '').trim();
      return doc.isNotEmpty;
    }).toList();
    double total = 0, itbis = 0;
    for (final r in filtrados) {
      total += (r['total'] as num?)?.toDouble() ?? 0;
      itbis += (r['itbis'] as num?)?.toDouble() ?? 0;
    }
    return {
      'titulo': '607 · Ventas DGII',
      'codigoDgii': '607',
      'total': total,
      'itbis': itbis,
      'cantidad': filtrados.length,
      'registros': filtrados,
      'columnas': ['Fecha', 'Cliente', 'NCF', 'Total', 'ITBIS'],
    };
  }

  Future<Map<String, dynamic>> reporte606(
    DateTime desde,
    DateTime hasta,
  ) async {
    final base = await reporteCompras(desde, hasta);
    final regs =
        (base['registros'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    // 606 DGII: preferir NCF; si no hay NCF, comprobante
    final filtrados = <Map<String, dynamic>>[];
    double total = 0, itbis = 0;
    for (final r in regs) {
      final ncf = (r['ncf']?.toString() ?? '').trim();
      final doc = (r['documento']?.toString() ?? '').trim();
      final idDoc = ncf.isNotEmpty ? ncf : doc;
      if (idDoc.isEmpty) continue;
      total += (r['total'] as num?)?.toDouble() ?? 0;
      itbis += (r['itbis'] as num?)?.toDouble() ?? 0;
      filtrados.add({...r, 'documento': idDoc, 'ncf': idDoc});
    }
    return {
      'titulo': '606 · Compras DGII',
      'codigoDgii': '606',
      'total': total,
      'itbis': itbis,
      'cantidad': filtrados.length,
      'registros': filtrados,
      'columnas': ['Fecha', 'Proveedor', 'NCF', 'Total', 'ITBIS'],
    };
  }

  Future<Map<String, dynamic>> generarPorTipo(
    String tipo,
    DateTime desde,
    DateTime hasta,
  ) async {
    return switch (tipo) {
      'ventas' => reporteVentas(desde, hasta),
      'compras' => reporteCompras(desde, hasta),
      'utilidades' => reporteUtilidades(desde, hasta),
      'productos' => reporteProductos(desde, hasta),
      'clientes' => reporteClientes(desde, hasta),
      'proveedores' => reporteProveedores(desde, hasta),
      '606' => reporte606(desde, hasta),
      '607' => reporte607(desde, hasta),
      _ => {
        'titulo': tipo,
        'total': 0.0,
        'cantidad': 0,
        'registros': <Map<String, dynamic>>[],
        'columnas': <String>[],
        'error': 'Tipo de reporte no soportado',
      },
    };
  }
}
