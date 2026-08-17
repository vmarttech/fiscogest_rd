import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/descuentos_table.dart';

part 'descuentos_dao.g.dart';

@DriftAccessor(tables: [DescuentosTable])
class DescuentosDao extends DatabaseAccessor<AppDatabase> with _$DescuentosDaoMixin {
  DescuentosDao(AppDatabase db) : super(db);
}
