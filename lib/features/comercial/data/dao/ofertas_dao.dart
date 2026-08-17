import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ofertas_table.dart';

part 'ofertas_dao.g.dart';

@DriftAccessor(tables: [OfertasTable])
class OfertasDao extends DatabaseAccessor<AppDatabase> with _$OfertasDaoMixin {
  OfertasDao(super.db);

  Future<List<OfertaData>> obtenerTodas() => select(ofertasTable).get();

  Future<OfertaData?> obtenerPorId(int id) =>
      (select(ofertasTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<OfertaData?> obtenerPorProducto(int productoId) =>
      (select(ofertasTable)..where((t) => t.productoId.equals(productoId))).getSingleOrNull();

  Future<int> insertar(OfertasTableCompanion oferta) =>
      into(ofertasTable).insert(oferta);

  Future<bool> actualizarEstado(int id, String estado) async {
    final filas = await (update(ofertasTable)..where((t) => t.id.equals(id)))
        .write(OfertasTableCompanion(estado: Value(estado)));
    return filas > 0;
  }

  Future<List<OfertaData>> obtenerVigentes(DateTime fecha) {
    return (select(ofertasTable)
      ..where((t) => t.vigenciaDesde.isSmallerOrEqualValue(fecha))
      ..where((t) => t.vigenciaHasta.isBiggerOrEqualValue(fecha))
      ..where((t) => t.estado.equals('Vigente'))
    ).get();
  }
}
