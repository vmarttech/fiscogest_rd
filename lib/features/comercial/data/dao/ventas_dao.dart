import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_detalle_table.dart';

part 'ventas_dao.g.dart';

@DriftAccessor(tables: [VentasTable, VentasDetalleTable])
class VentasDao extends DatabaseAccessor<AppDatabase> with _$VentasDaoMixin {
  VentasDao(AppDatabase db) : super(db);
}
