import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/descuentos_table.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
part 'descuentos_dao.g.dart';

@DriftAccessor(tables: [DescuentosTable])
class DescuentosDao extends DatabaseAccessor<AppDatabase> with _$DescuentosDaoMixin {
  DescuentosDao(AppDatabase db) : super(db);

  Future<List<DescuentoData>> listarDescuentosActivos() async {
    final ahora = DateTime.now();
    final consulta = select(descuentosTable)
      ..where((t) => 
        t.estado.equals(RegistroEstado.vigente.name) &
        t.vigenciaDesde.isSmallerOrEqualValue(ahora) &
        t.vigenciaHasta.isBiggerOrEqualValue(ahora)
      )
      ..orderBy([(t) => OrderingTerm(expression: t.nombre)]);
    return consulta.get();
  }

  Future<bool> aplicarDescuento(int ventaId, int descuentoId) async {
    return true;
  }
}
