import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_detalle_table.dart';
part 'apartados_dao.g.dart';

@DriftAccessor(tables: [ApartadosTable, ApartadosDetalleTable])
class ApartadosDao extends DatabaseAccessor<AppDatabase> with _$ApartadosDaoMixin {
  ApartadosDao(AppDatabase db) : super(db);

  Future<List<Map<String, dynamic>>> listarApartados() async {
    final query = select(apartadosTable)
      ..orderBy([(t) => OrderingTerm(expression: t.fechaReserva, mode: OrderingMode.desc)]);

    final resultados = await query.get();
    return resultados.map((a) {
      final json = a.toJson();
      json['fechaApartado'] = a.fechaReserva;
      json['fechaLimitePago'] = a.fechaLimite;
      return json;
    }).toList();
  }
}
