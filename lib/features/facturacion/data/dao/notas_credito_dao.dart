import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/facturacion/data/dao/notas_credito_table.dart';

part 'notas_credito_dao.g.dart';

@DriftAccessor(tables: [NotasCreditoTable])
class NotasCreditoDao extends DatabaseAccessor<AppDatabase>
    with _$NotasCreditoDaoMixin {
  NotasCreditoDao(super.db);

  Future<int> insertar(NotasCreditoTableCompanion row) {
    return into(notasCreditoTable).insert(row);
  }

  Future<List<NotasCreditoTableData>> listar() {
    return (select(
      notasCreditoTable,
    )..orderBy([(t) => OrderingTerm.desc(t.creadoEn)])).get();
  }
}
