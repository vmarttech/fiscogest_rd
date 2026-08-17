import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/devoluciones_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/devoluciones_detalle_table.dart';

part 'devoluciones_dao.g.dart';

@DriftAccessor(tables: [DevolucionesTable, DevolucionesDetalleTable])
class DevolucionesDao extends DatabaseAccessor<AppDatabase> with _$DevolucionesDaoMixin {
  DevolucionesDao(super.db);

  Future<List<DevolucionData>> obtenerTodas() => select(devolucionesTable).get();

  Future<DevolucionData?> obtenerPorId(int id) =>
      (select(devolucionesTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertar(DevolucionesTableCompanion devolucion) =>
      into(devolucionesTable).insert(devolucion);

  Future<bool> actualizarEstado(int id, String estado) async {
    final filas = await (update(devolucionesTable)..where((t) => t.id.equals(id)))
        .write(DevolucionesTableCompanion(estado: Value(estado)));
    return filas > 0;
  }

  Future<List<DevolucionData>> listarPorFiltros({
    DateTime? desde,
    DateTime? hasta,
    int? ventaId,
    String? estado,
  }) {
    final query = select(devolucionesTable);
    if (desde != null) query.where((t) => t.fecha.isBiggerOrEqualValue(desde));
    if (hasta != null) query.where((t) => t.fecha.isSmallerOrEqualValue(hasta));
    if (ventaId != null) query.where((t) => t.ventaId.equals(ventaId));
    if (estado != null) query.where((t) => t.estado.equals(estado));
    query.orderBy([(t) => OrderingTerm(expression: t.fecha, mode: OrderingMode.desc)]);
    return query.get();
  }

  Future<List<DevolucionDetalleData>> obtenerDetallesPorDevolucion(int devolucionId) =>
      (select(devolucionesDetalleTable)..where((t) => t.devolucionId.equals(devolucionId))).get();

  Future<int> registrarDevolucionCompleta(
    DevolucionesTableCompanion devolucion,
    List<DevolucionesDetalleTableCompanion> detalles,
  ) async {
    return transaction(() async {
      final devolucionId = await into(devolucionesTable).insert(devolucion);
      final detallesConId = detalles
          .map((d) => d.copyWith(devolucionId: Value(devolucionId)))
          .toList();
      await batch((batch) => batch.insertAll(devolucionesDetalleTable, detallesConId));
      return devolucionId;
    });
  }
}
