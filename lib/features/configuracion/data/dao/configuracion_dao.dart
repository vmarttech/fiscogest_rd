import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/configuracion/data/dao/configuracion_table.dart';

part 'configuracion_dao.g.dart';

@DriftAccessor(tables: [ConfiguracionTable])
class ConfiguracionDao extends DatabaseAccessor<AppDatabase> with _$ConfiguracionDaoMixin {
  ConfiguracionDao(super.db);

  Future<ConfiguracionTableData?> obtenerConfiguracion() =>
      select(configuracionTable).getSingleOrNull();

  Future<int> guardarConfiguracion(ConfiguracionTableCompanion companion) =>
      into(configuracionTable).insertOnConflictUpdate(companion);
}