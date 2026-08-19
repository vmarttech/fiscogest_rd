import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_detalle_table.dart';
part 'ventas_dao.g.dart';

@DriftAccessor(tables: [VentasTable, VentasDetalleTable])
class VentasDao extends DatabaseAccessor<AppDatabase> with _$VentasDaoMixin {
  VentasDao(AppDatabase db) : super(db);

  Future<List<Map<String, dynamic>>> listarVentas({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  }) async {
    final query = select(ventasTable);

    if (desde != null) {
      query.where((VentasTable t) => t.fecha.isBiggerOrEqualValue(desde));
    }
    if (hasta != null) {
      query.where((VentasTable t) => t.fecha.isSmallerOrEqualValue(hasta));
    }
    if (clienteId != null) {
      query.where((VentasTable t) => t.clienteId.equals(clienteId));
    }
    if (usuarioId != null) {
      query.where((VentasTable t) => t.usuarioId.equals(usuarioId));
    }

    query.orderBy([(VentasTable t) => OrderingTerm(expression: t.fecha, mode: OrderingMode.desc)]);

    final List<VentaData> resultados = await query.get();
    return resultados.map((VentaData v) => v.toJson()).toList();
  }
}
