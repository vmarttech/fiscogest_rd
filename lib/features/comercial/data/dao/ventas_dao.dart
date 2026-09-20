import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
typedef VentaConCliente = ({VentasTableData venta, String? nombreCliente});

class VentasDao {
  VentasDao(this._db);
  final AppDatabase _db;

  Future<int> insertarVenta(final VentasTableCompanion venta) async {
    return await _db.into(_db.ventasTable).insert(venta);
  }

  Future<List<VentaConCliente>> listarVentas({
    final DateTime? desde,
    final DateTime? hasta,
    final int? clienteId,
    final int? usuarioId,
  }) async {
    final query = _db.select(_db.ventasTable)
      ..orderBy([(final t) => OrderingTerm.desc(t.fechaRegistro)]);
    if (desde != null) {
      query.where((final t) => t.fechaRegistro.isBiggerOrEqualValue(desde));
    }
    if (hasta != null) {
      query.where((final t) => t.fechaRegistro.isSmallerOrEqualValue(hasta));
    }
    if (clienteId != null) {
      query.where((final t) => t.clienteId.equals(clienteId));
    }
    if (usuarioId != null) {
      query.where((final t) => t.usuarioId.equals(usuarioId));
    }
    final filas = await query.get();
    return filas.map((final v) => (venta: v, nombreCliente: null)).toList();
  }

  Future<List<VentaConCliente>> listarCotizaciones({
    final DateTime? desde,
    final DateTime? hasta,
    final int? clienteId,
    final int? usuarioId,
  }) async {
    final query = _db.select(_db.ventasTable)
      ..where((final t) => t.estadoDocumento.equals('cotizado'))
      ..orderBy([(final t) => OrderingTerm.desc(t.fechaRegistro)]);
    if (desde != null) {
      query.where((final t) => t.fechaRegistro.isBiggerOrEqualValue(desde));
    }
    if (hasta != null) {
      query.where((final t) => t.fechaRegistro.isSmallerOrEqualValue(hasta));
    }
    if (clienteId != null) {
      query.where((final t) => t.clienteId.equals(clienteId));
    }
    if (usuarioId != null) {
      query.where((final t) => t.usuarioId.equals(usuarioId));
    }
    final filas = await query.get();
    return filas.map((final v) => (venta: v, nombreCliente: null)).toList();
  }

  Future<VentasTableData?> obtenerVentaPorId(final int ventaId) async {
    return await (_db.select(_db.ventasTable)
          ..where((final t) => t.id.equals(ventaId)))
        .getSingleOrNull();
  }

  Future<bool> actualizarVenta(
    final int ventaId,
    final VentasTableCompanion venta,
  ) async {
    return await (_db.update(_db.ventasTable)
      ..where((final t) => t.id.equals(ventaId)))
          .replace(venta);
  }

  Future<int> obtenerUltimoCorrelativoCotizacion({bool? soloCredito}) async {
    final query = _db.select(_db.ventasTable)
      ..where((final t) => t.numeroCotizacion.isNotNull());
    if (soloCredito == true) {
      query.where((final t) => t.numeroCotizacion.like('CR-%'));
    } else if (soloCredito == false) {
      query.where((final t) => t.numeroCotizacion.like('C-%'));
    }
    query.orderBy([(final t) => OrderingTerm.desc(t.numeroCotizacion)]);
    query.limit(1);
    final filas = await query.get();
    if (filas.isEmpty) return 0;
    final ultimo = filas.first.numeroCotizacion;
    final soloNumero = ultimo.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(soloNumero) ?? 0;
  }
}
