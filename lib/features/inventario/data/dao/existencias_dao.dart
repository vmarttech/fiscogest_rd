import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/existencias_table.dart';
part 'existencias_dao.g.dart';

@DriftAccessor(tables: [ExistenciasTable])
class ExistenciasDao extends DatabaseAccessor<AppDatabase> with _$ExistenciasDaoMixin {
  ExistenciasDao(AppDatabase db) : super(db);

  Future<bool> descontarExistencia(int productoId, double cantidad) async {
    final fila = await (select(existenciasTable)
      ..where((t) => t.productoId.equals(productoId)))
      .getSingleOrNull();
    if (fila == null) return false;
    final nuevaActual = fila.existenciaActual - cantidad;
    final nuevaDisponible = fila.existenciaDisponible - cantidad;
    final ahora = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final filasAfectadas = await (update(existenciasTable)
      ..where((t) => t.productoId.equals(productoId)))
      .write(ExistenciasTableCompanion(
        existenciaActual: Value(nuevaActual),
        existenciaDisponible: Value(nuevaDisponible),
        fechaActualizacion: Value(ahora),
      ));
    return filasAfectadas > 0;
  }
}
