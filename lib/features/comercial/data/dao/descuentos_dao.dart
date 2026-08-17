import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/descuentos_table.dart';

part 'descuentos_dao.g.dart';

@DriftAccessor(tables: [DescuentosTable])
class DescuentosDao extends DatabaseAccessor<AppDatabase> with _$DescuentosDaoMixin {
  DescuentosDao(super.db);

  Future<List<DescuentoData>> obtenerTodos() => select(descuentosTable).get();

  Future<DescuentoData?> obtenerPorId(int id) =>
      (select(descuentosTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertar(DescuentosTableCompanion descuento) =>
      into(descuentosTable).insert(descuento);

  Future<int> insertarOActualizar(DescuentosTableCompanion descuento) =>
      into(descuentosTable).insertOnConflictUpdate(descuento);

  Future<bool> actualizarEstado(int id, String estado) async {
    final filas = await (update(descuentosTable)..where((t) => t.id.equals(id)))
        .write(DescuentosTableCompanion(estado: Value(estado)));
    return filas > 0;
  }

  Future<List<DescuentoData>> obtenerVigentes(DateTime fecha) {
    return (select(descuentosTable)
      ..where((t) => t.vigenciaDesde.isSmallerOrEqualValue(fecha))
      ..where((t) => t.vigenciaHasta.isBiggerOrEqualValue(fecha))
      ..where((t) => t.estado.equals('Vigente'))
    ).get();
  }
}
