import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/reportes/domain/kpi_models.dart';
import 'package:intl/intl.dart';

/// Agregados de ventas cobradas (facturado + enCredito).
class ReportesRepository {
  ReportesRepository(this._db);
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
    return KpiPeriodo(
      ventas: actual.$1,
      numFacturas: actual.$2,
      ganancia: actual.$3,
      ventasAnterior: ant.$1,
      gananciaAnterior: ant.$3,
    );
  }

  /// (ventas, num, ganancia)
  Future<(double, int, double)> _agregado(DateTime desde, DateTime hasta) async {
    final ds = desde.toIso8601String();
    final hs = hasta.toIso8601String();

    final rows = await _db.customSelect(
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
        Variable.withString(ds),
        Variable.withString(hs),
      ],
      readsFrom: {_db.ventasTable, _db.ventasDetalleTable, _db.productosTable},
    ).get();

    if (rows.isEmpty) return (0.0, 0, 0.0);
    final r = rows.first;
    final ventas = (r.data['ventas'] as num?)?.toDouble() ?? 0.0;
    final n = (r.data['n'] as num?)?.toInt() ?? 0;
    final costo = (r.data['costo'] as num?)?.toDouble() ?? 0.0;
    return (ventas, n, ventas - costo);
  }

  Future<List<SeriePunto>> _serieDiaria(DateTime desde, DateTime hasta) async {
    final rows = await _db.customSelect(
      '''
      SELECT date(v.fecha) AS dia,
             COALESCE(SUM(v.monto_total), 0.0) AS total
      FROM ventas_table v
      WHERE v.fecha >= ? AND v.fecha < ?
        AND v.estado_documento IN $_estadosVenta
      GROUP BY date(v.fecha)
      ORDER BY dia
      ''',
      variables: [
        Variable.withString(desde.toIso8601String()),
        Variable.withString(hasta.toIso8601String()),
      ],
      readsFrom: {_db.ventasTable},
    ).get();

    final map = <String, double>{};
    for (final r in rows) {
      final dia = r.data['dia']?.toString() ?? '';
      map[dia] = (r.data['total'] as num?)?.toDouble() ?? 0.0;
    }

    final out = <SeriePunto>[];
    final fmt = DateFormat('d/M');
    for (var i = 0; i < 30; i++) {
      final d = DateTime(desde.year, desde.month, desde.day)
          .add(Duration(days: i));
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
    final rows = await _db.customSelect(
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
        Variable.withString(desde.toIso8601String()),
        Variable.withString(hasta.toIso8601String()),
      ],
      readsFrom: {_db.ventasTable},
    ).get();

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
    final rows = await _db.customSelect(
      '''
      SELECT COALESCE(p.nombre, 'Producto') AS nombre,
             COALESCE(SUM(d.cantidad), 0.0) AS cant,
             COALESCE(SUM(d.subtotal), 0.0) AS monto
      FROM ventas_detalle_table d
      INNER JOIN ventas_table v ON v.id = d.venta_id
      LEFT JOIN productos_table p ON p.id = d.producto_id
      WHERE v.fecha >= ? AND v.fecha < ?
        AND v.estado_documento IN $_estadosVenta
      GROUP BY d.producto_id
      ORDER BY monto DESC
      LIMIT ?
      ''',
      variables: [
        Variable.withString(desde.toIso8601String()),
        Variable.withString(hasta.toIso8601String()),
        Variable.withInt(limit),
      ],
      readsFrom: {
        _db.ventasTable,
        _db.ventasDetalleTable,
        _db.productosTable,
      },
    ).get();

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
}
