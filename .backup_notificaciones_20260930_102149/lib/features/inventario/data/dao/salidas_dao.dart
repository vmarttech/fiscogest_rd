import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/salidas_table.dart';
part 'salidas_dao.g.dart';

@DriftAccessor(tables: [SalidasTable])
class SalidasDao extends DatabaseAccessor<AppDatabase> with _$SalidasDaoMixin {
  SalidasDao(super.db);

  Future<int> registrarSalida({
    required int productoId,
    required double cantidad,
    required String motivo,
    String? usuario,
    String? observacion,
  }) async {
    final fechaUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return into(salidasTable).insert(
      SalidasTableCompanion(
        productoId: Value(productoId),
        cantidad: Value(cantidad),
        motivo: Value(motivo),
        fecha: Value(fechaUnix),
        usuario: Value(usuario ?? 'sistema'),
        observacion: observacion != null
            ? Value(observacion)
            : const Value.absent(),
      ),
    );
  }
}
