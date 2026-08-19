import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ofertas_table.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
part 'ofertas_dao.g.dart';

@DriftAccessor(tables: [OfertasTable])
class OfertasDao extends DatabaseAccessor<AppDatabase> with _$OfertasDaoMixin {
  OfertasDao(AppDatabase db) : super(db);

  Future<List<OfertaData>> listarOfertasActivas() async {
    final ahora = DateTime.now();
    final consulta = select(ofertasTable)
      ..where((t) => 
        t.estado.equals(RegistroEstado.vigente.name) &
        t.vigenciaDesde.isSmallerOrEqualValue(ahora) &
        t.vigenciaHasta.isBiggerOrEqualValue(ahora)
      )
      ..orderBy([(t) => OrderingTerm(expression: t.nombre)]);
    return consulta.get();
  }

  Future<bool> validarOferta(int ofertaId, double montoCompra) async {
    final consulta = select(ofertasTable)
      ..where((t) => t.id.equals(ofertaId));
    final oferta = await consulta.getSingleOrNull();
    if (oferta == null) return false;
    final ahora = DateTime.now();
    final vigente = oferta.vigenciaDesde.isBefore(ahora.add(const Duration(seconds: 1))) &&
                    oferta.vigenciaHasta.isAfter(ahora.subtract(const Duration(seconds: 1)));
    if (!vigente) return false;
    return montoCompra >= oferta.cantidadMinima;
  }
}
