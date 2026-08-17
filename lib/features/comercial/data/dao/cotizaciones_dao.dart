import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cotizaciones_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cotizaciones_detalle_table.dart';

part 'cotizaciones_dao.g.dart';

@DriftAccessor(tables: [CotizacionesTable, CotizacionesDetalleTable])
class CotizacionesDao extends DatabaseAccessor<AppDatabase> with _$CotizacionesDaoMixin {
  CotizacionesDao(super.db);

  Future<List<CotizacionData>> obtenerTodas() => select(cotizacionesTable).get();

  Future<CotizacionData?> obtenerPorId(int id) =>
      (select(cotizacionesTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertar(CotizacionesTableCompanion cotizacion) =>
      into(cotizacionesTable).insert(cotizacion);

  Future<int> insertarOActualizar(CotizacionesTableCompanion cotizacion) =>
      into(cotizacionesTable).insertOnConflictUpdate(cotizacion);

  Future<bool> actualizarEstado(int id, String estado) async {
    final filas = await (update(cotizacionesTable)..where((t) => t.id.equals(id)))
        .write(CotizacionesTableCompanion(estado: Value(estado)));
    return filas > 0;
  }

  Future<bool> marcarConvertida(int id, int ventaId) async {
    final filas = await (update(cotizacionesTable)..where((t) => t.id.equals(id)))
        .write(CotizacionesTableCompanion(
          estado: const Value('Convertida'),
          ventaConvertidaId: Value(ventaId),
        ));
    return filas > 0;
  }

  Future<List<CotizacionData>> listarPorFiltros({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    String? estado,
  }) {
    final query = select(cotizacionesTable);
    if (desde != null) query.where((t) => t.fechaEmision.isBiggerOrEqualValue(desde));
    if (hasta != null) query.where((t) => t.fechaEmision.isSmallerOrEqualValue(hasta));
    if (clienteId != null) query.where((t) => t.clienteId.equals(clienteId));
    if (estado != null) query.where((t) => t.estado.equals(estado));
    query.orderBy([(t) => OrderingTerm(expression: t.fechaEmision, mode: OrderingMode.desc)]);
    return query.get();
  }

  Future<List<CotizacionDetalleData>> obtenerDetallesPorCotizacion(int cotizacionId) =>
      (select(cotizacionesDetalleTable)..where((t) => t.cotizacionId.equals(cotizacionId))).get();

  Future<int> registrarCotizacionCompleta(
    CotizacionesTableCompanion cotizacion,
    List<CotizacionesDetalleTableCompanion> detalles,
  ) async {
    return transaction(() async {
      final cotizacionId = await into(cotizacionesTable).insert(cotizacion);
      final detallesConId = detalles
          .map((d) => d.copyWith(cotizacionId: Value(cotizacionId)))
          .toList();
      await batch((batch) => batch.insertAll(cotizacionesDetalleTable, detallesConId));
      return cotizacionId;
    });
  }
}
