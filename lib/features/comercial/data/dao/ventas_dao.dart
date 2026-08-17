import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_detalle_table.dart';

part 'ventas_dao.g.dart';

@DriftAccessor(tables: [VentasTable, VentasDetalleTable])
class VentasDao extends DatabaseAccessor<AppDatabase> with _$VentasDaoMixin {
  VentasDao(super.db);

  Future<List<VentaData>> obtenerTodas() => select(ventasTable).get();

  Future<VentaData?> obtenerPorId(int id) =>
      (select(ventasTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertar(VentasTableCompanion venta) =>
      into(ventasTable).insert(venta);

  Future<int> insertarOActualizar(VentasTableCompanion venta) =>
      into(ventasTable).insertOnConflictUpdate(venta);

  Future<bool> actualizarEstado(int id, String estado) async {
    final filas = await (update(ventasTable)..where((t) => t.id.equals(id)))
        .write(VentasTableCompanion(estado: Value(estado)));
    return filas > 0;
  }

  Future<bool> eliminar(int id) async {
    final filas = await (delete(ventasTable)..where((t) => t.id.equals(id))).go();
    return filas > 0;
  }

  Future<List<VentaData>> listarPorFiltros({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
    String? estado,
  }) {
    final query = select(ventasTable);
    if (desde != null) query.where((t) => t.fecha.isBiggerOrEqualValue(desde));
    if (hasta != null) query.where((t) => t.fecha.isSmallerOrEqualValue(hasta));
    if (clienteId != null) query.where((t) => t.clienteId.equals(clienteId));
    if (usuarioId != null) query.where((t) => t.usuarioId.equals(usuarioId));
    if (estado != null) query.where((t) => t.estado.equals(estado));
    query.orderBy([(t) => OrderingTerm(expression: t.fecha, mode: OrderingMode.desc)]);
    return query.get();
  }

  Future<List<VentaDetalleData>> obtenerDetallesPorVenta(int ventaId) =>
      (select(ventasDetalleTable)..where((t) => t.ventaId.equals(ventaId))).get();

  Future<void> insertarDetalles(List<VentasDetalleTableCompanion> detalles) =>
      batch((batch) => batch.insertAll(ventasDetalleTable, detalles));

  Future<bool> eliminarDetallesPorVenta(int ventaId) async {
    final filas = await (delete(ventasDetalleTable)..where((t) => t.ventaId.equals(ventaId))).go();
    return filas > 0;
  }

  Future<int> registrarVentaCompleta(
    VentasTableCompanion venta,
    List<VentasDetalleTableCompanion> detalles,
  ) async {
    return transaction(() async {
      final ventaId = await into(ventasTable).insert(venta);
      final detallesConId = detalles
          .map((d) => d.copyWith(ventaId: Value(ventaId)))
          .toList();
      await batch((batch) => batch.insertAll(ventasDetalleTable, detallesConId));
      return ventaId;
    });
  }
}
