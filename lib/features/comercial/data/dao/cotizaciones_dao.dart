import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cotizaciones_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cotizaciones_detalle_table.dart';
part 'cotizaciones_dao.g.dart';

@DriftAccessor(tables: [CotizacionesTable, CotizacionesDetalleTable])
class CotizacionesDao extends DatabaseAccessor<AppDatabase> with _$CotizacionesDaoMixin {
  CotizacionesDao(AppDatabase db) : super(db);

  Future<List<Map<String, dynamic>>> listarCotizaciones() async {
    final query = select(cotizacionesTable)
      ..orderBy([(CotizacionesTable t) => OrderingTerm(expression: t.fechaEmision, mode: OrderingMode.desc)]);

    final List<CotizacionData> resultados = await query.get();
    return resultados.map((CotizacionData c) {
      final json = c.toJson();
      json['convertida_a_venta'] = c.ventaConvertidaId != null;
      return json;
    }).toList();
  }

  Future<int> insertarCotizacion(CotizacionesTableCompanion cotizacion) async {
    return into(cotizacionesTable).insert(cotizacion);
  }

  Future<bool> marcarComoConvertida(int cotizacionId, int ventaId) async {
    final filasAfectadas = await (update(cotizacionesTable)
      ..where((CotizacionesTable t) => t.id.equals(cotizacionId)))
      .write(CotizacionesTableCompanion(ventaConvertidaId: Value(ventaId)));
    return filasAfectadas > 0;
  }

  Future<CotizacionData?> buscarPorId(int cotizacionId) async {
    return (select(cotizacionesTable)..where((CotizacionesTable t) => t.id.equals(cotizacionId))).getSingleOrNull();
  }
}
