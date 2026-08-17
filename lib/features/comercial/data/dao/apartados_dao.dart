import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_detalle_table.dart';

part 'apartados_dao.g.dart';

@DriftAccessor(tables: [ApartadosTable, ApartadosDetalleTable])
class ApartadosDao extends DatabaseAccessor<AppDatabase> with _$ApartadosDaoMixin {
  ApartadosDao(AppDatabase db) : super(db);
}
