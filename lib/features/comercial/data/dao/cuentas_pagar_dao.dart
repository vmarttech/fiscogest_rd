import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_pagar_table.dart';

part 'cuentas_pagar_dao.g.dart';

@DriftAccessor(tables: [CuentasPagarTable])
class CuentasPagarDao extends DatabaseAccessor<AppDatabase>
    with _$CuentasPagarDaoMixin {
  CuentasPagarDao(super.db);
}
