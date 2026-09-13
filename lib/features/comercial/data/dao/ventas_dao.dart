import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
typedef VentaConCliente = ({VentasTableData venta, String? nombreCliente});
class VentasDao {
  VentasDao(this._db);
  final AppDatabase _db;
  Future<int> insertarVenta(VentasTableCompanion venta) async {
    return await _db.into(_db.ventasTable).insert(venta);
  }
  Future<List<VentaConCliente>> listarVentas({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  }) async {
    final query = _db.select(_db.ventasTable)
      ..orderBy([(t) => OrderingTerm.desc(t.fechaRegistro)]);
    if (desde != null) {
      query.where((t) => t.fechaRegistro.isBiggerOrEqualValue(desde));
    }
    if (hasta != null) {
      query.where((t) => t.fechaRegistro.isSmallerOrEqualValue(hasta));
    }
    if (clienteId != null) {
      query.where((t) => t.clienteId.equals(clienteId));
    }
    if (usuarioId != null) {
      query.where((t) => t.usuarioId.equals(usuarioId));
    }
    final filas = await query.get();
    return filas.map((v) => (venta: v, nombreCliente: null)).toList();
  }
  Future<List<VentaConCliente>> listarCotizaciones({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  }) async {
    final query = _db.select(_db.ventasTable)
      ..where((t) => t.estadoDocumento.equals('cotizado'))
      ..orderBy([(t) => OrderingTerm.desc(t.fechaRegistro)]);
    if (desde != null) {
      query.where((t) => t.fechaRegistro.isBiggerOrEqualValue(desde));
    }
    if (hasta != null) {
      query.where((t) => t.fechaRegistro.isSmallerOrEqualValue(hasta));
    }
    if (clienteId != null) {
      query.where((t) => t.clienteId.equals(clienteId));
    }
    if (usuarioId != null) {
      query.where((t) => t.usuarioId.equals(usuarioId));
    }
    final filas = await query.get();
    return filas.map((v) => (venta: v, nombreCliente: null)).toList();
  }
  Future<VentasTableData?> obtenerVentaPorId(int ventaId) async {
    return await (_db.select(_db.ventasTable)
          ..where((t) => t.id.equals(ventaId)))
        .getSingleOrNull();
  }
  Future<bool> actualizarVenta(int ventaId, VentasTableCompanion venta) async {
    return await (_db.update(_db.ventasTable)
      ..where((t) => t.id.equals(ventaId)))
        .replace(venta);
  }
  // ✅ NUEVO: Obtener último número de cotización
  Future<int> obtenerUltimoCorrelativoCotizacion() async {
    final filas = await (_db.select(_db.ventasTable)
      ..where((t) => t.numeroCotizacion.isNotNull())
      ..orderBy([(t) => OrderingTerm.desc(t.numeroCotizacion)])
      ..limit(1)).get();
    if (filas.isEmpty) return 0;
    final ultimo = filas.first.numeroCotizacion;
    if (!ultimo.startsWith('COT-')) return 0;
    final soloNumero = ultimo.replaceFirst('COT-', '');
    return int.tryParse(soloNumero) ?? 0;
  }
}
