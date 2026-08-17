import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cotizaciones_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cotizaciones_detalle_table.dart';

part 'cotizaciones_dao.g.dart';

@DriftAccessor(tables: [CotizacionesTable, CotizacionesDetalleTable])
class CotizacionesDao extends DatabaseAccessor<AppDatabase> with _$CotizacionesDaoMixin {
  CotizacionesDao(AppDatabase db) : super(db);
}
