import 'package:fiscogestrd/models/operacion.dart';
import 'package:fiscogestrd/repositories/database_helper.dart';

class OperacionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ─── COMPRAS ───
  Future<int> guardarCompra(Compra compra) async {
    final db = await _dbHelper.database;
    final compraId = await db.insert('compras', compra.toMap());

    for (final detalle in compra.detalles) {
      await db.insert('detalles_operacion', {
        ...detalle.toMap(),
        'tipoOperacion': 'compra',
        'operacionId': compraId,
      });
    }
    return compraId;
  }

  Future<List<Compra>> obtenerCompras({DateTime? desde, DateTime? hasta}) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final args = <dynamic>[];

    if (desde != null) {
      where.add('fecha >= ?');
      args.add(desde.toIso8601String());
    }
    if (hasta != null) {
      where.add('fecha <= ?');
      args.add(hasta.toIso8601String());
    }

    final comprasMap = await db.query(
      'compras',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: args,
      orderBy: 'fecha DESC',
    );

    final List<Compra> lista = [];
    for (final c in comprasMap) {
      final detallesMap = await db.query(
        'detalles_operacion',
        where: 'tipoOperacion = ? AND operacionId = ?',
        whereArgs: ['compra', c['id']],
      );
      final detalles = detallesMap.map((d) => DetalleOperacion.fromMap(d)).toList();
      lista.add(Compra.fromMap(c, detalles));
    }
    return lista;
  }

  // ─── VENTAS ───
  Future<int> guardarVenta(Venta venta) async {
    final db = await _dbHelper.database;
    final ventaId = await db.insert('ventas', venta.toMap());

    for (final detalle in venta.detalles) {
      await db.insert('detalles_operacion', {
        ...detalle.toMap(),
        'tipoOperacion': 'venta',
        'operacionId': ventaId,
      });
    }
    return ventaId;
  }

  Future<List<Venta>> obtenerVentas({DateTime? desde, DateTime? hasta}) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final args = <dynamic>[];

    if (desde != null) {
      where.add('fecha >= ?');
      args.add(desde.toIso8601String());
    }
    if (hasta != null) {
      where.add('fecha <= ?');
      args.add(hasta.toIso8601String());
    }

    final ventasMap = await db.query(
      'ventas',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: args,
      orderBy: 'fecha DESC',
    );

    final List<Venta> lista = [];
    for (final v in ventasMap) {
      final detallesMap = await db.query(
        'detalles_operacion',
        where: 'tipoOperacion = ? AND operacionId = ?',
        whereArgs: ['venta', v['id']],
      );
      final detalles = detallesMap.map((d) => DetalleOperacion.fromMap(d)).toList();
      lista.add(Venta.fromMap(v, detalles));
    }
    return lista;
  }
}