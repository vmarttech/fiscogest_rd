import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/devoluciones_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/devoluciones_detalle_table.dart';
part 'devoluciones_dao.g.dart';

@DriftAccessor(tables: [DevolucionesTable, DevolucionesDetalleTable])
class DevolucionesDao extends DatabaseAccessor<AppDatabase> with _$DevolucionesDaoMixin {
  DevolucionesDao(AppDatabase db) : super(db);

  Future<int> insertarDevolucion(DevolucionesTableCompanion devolucion) async {
    return into(devolucionesTable).insert(devolucion);
  }
}
