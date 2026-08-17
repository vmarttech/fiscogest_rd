import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_detalle_table.dart';

part 'apartados_dao.g.dart';

@DriftAccessor(tables: [ApartadosTable, ApartadosDetalleTable])
class ApartadosDao extends DatabaseAccessor<AppDatabase> with _$ApartadosDaoMixin {
  ApartadosDao(super.db);

  Future<List<ApartadoData>> obtenerTodos() => select(apartadosTable).get();

  Future<ApartadoData?> obtenerPorId(int id) =>
      (select(apartadosTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertar(ApartadosTableCompanion apartado) =>
      into(apartadosTable).insert(apartado);

  Future<bool> actualizarEstado(int id, String estado) async {
    final filas = await (update(apartadosTable)..where((t) => t.id.equals(id)))
        .write(ApartadosTableCompanion(estado: Value(estado)));
    return filas > 0;
  }

  Future<bool> actualizarAbono(int id, double montoAbonado, double saldoPendiente) async {
    final filas = await (update(apartadosTable)..where((t) => t.id.equals(id)))
        .write(ApartadosTableCompanion(
          montoAbonado: Value(montoAbonado),
          saldoPendiente: Value(saldoPendiente),
        ));
    return filas > 0;
  }

  Future<bool> marcarConvertido(int id, int ventaId) async {
    final filas = await (update(apartadosTable)..where((t) => t.id.equals(id)))
        .write(ApartadosTableCompanion(
          estado: const Value('Convertido'),
          ventaConvertidaId: Value(ventaId),
        ));
    return filas > 0;
  }

  Future<List<ApartadoData>> listarPorFiltros({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    String? estado,
  }) {
    final query = select(apartadosTable);
    if (desde != null) query.where((t) => t.fechaReserva.isBiggerOrEqualValue(desde));
    if (hasta != null) query.where((t) => t.fechaReserva.isSmallerOrEqualValue(hasta));
    if (clienteId != null) query.where((t) => t.clienteId.equals(clienteId));
    if (estado != null) query.where((t) => t.estado.equals(estado));
    query.orderBy([(t) => OrderingTerm(expression: t.fechaReserva, mode: OrderingMode.desc)]);
    return query.get();
  }

  Future<List<ApartadoDetalleData>> obtenerDetallesPorApartado(int apartadoId) =>
      (select(apartadosDetalleTable)..where((t) => t.apartadoId.equals(apartadoId))).get();

  Future<int> registrarApartadoCompleto(
    ApartadosTableCompanion apartado,
    List<ApartadosDetalleTableCompanion> detalles,
  ) async {
    return transaction(() async {
      final apartadoId = await into(apartadosTable).insert(apartado);
      final detallesConId = detalles
          .map((d) => d.copyWith(apartadoId: Value(apartadoId)))
          .toList();
      await batch((batch) => batch.insertAll(apartadosDetalleTable, detallesConId));
      return apartadoId;
    });
  }
}
