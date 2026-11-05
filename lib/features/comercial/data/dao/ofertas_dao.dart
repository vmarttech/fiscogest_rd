import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ofertas_table.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
part 'ofertas_dao.g.dart';

@DriftAccessor(tables: [OfertasTable])
class OfertasDao extends DatabaseAccessor<AppDatabase> with _$OfertasDaoMixin {
  OfertasDao(super.db);

  Future<List<OfertaData>> listarOfertasActivas() async {
    final ahora = DateTime.now();
    final consulta = select(ofertasTable)
      ..where(
        (t) =>
            t.estado.equals(RegistroEstado.vigente.name) &
            t.vigenciaDesde.isSmallerOrEqualValue(ahora) &
            t.vigenciaHasta.isBiggerOrEqualValue(ahora),
      )
      ..orderBy([(t) => OrderingTerm(expression: t.nombre)]);
    return consulta.get();
  }

  Future<List<OfertaData>> listarTodas() {
    final consulta = select(ofertasTable)
      ..orderBy([(t) => OrderingTerm(expression: t.nombre)]);
    return consulta.get();
  }

  Future<OfertaData?> obtenerPorId(int id) {
    return (select(
      ofertasTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> crear(OfertasTableCompanion oferta) {
    return into(ofertasTable).insert(oferta);
  }

  Future<bool> actualizar(int id, OfertasTableCompanion cambios) async {
    final filas = await (update(
      ofertasTable,
    )..where((t) => t.id.equals(id))).write(cambios);
    return filas > 0;
  }

  Future<int> eliminar(int id) {
    return (delete(ofertasTable)..where((t) => t.id.equals(id))).go();
  }

  /// [cantidadCompra] representa unidades del producto, no dinero.
  Future<bool> validarOferta(int ofertaId, double cantidadCompra) async {
    final oferta = await obtenerPorId(ofertaId);
    if (oferta == null) return false;

    final ahora = DateTime.now();

    final vigente =
        oferta.estado == RegistroEstado.vigente &&
        !ahora.isBefore(oferta.vigenciaDesde) &&
        !ahora.isAfter(oferta.vigenciaHasta);

    if (!vigente) return false;

    return cantidadCompra >= oferta.cantidadMinima;
  }
}
