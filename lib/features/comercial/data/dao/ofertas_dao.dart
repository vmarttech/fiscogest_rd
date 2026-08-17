import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ofertas_table.dart';

part 'ofertas_dao.g.dart';

@DriftAccessor(tables: [OfertasTable])
class OfertasDao extends DatabaseAccessor<AppDatabase> with _$OfertasDaoMixin {
  OfertasDao(AppDatabase db) : super(db);
}
