import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/proveedores/data/dao/proveedores_table.dart';
part 'proveedores_dao.g.dart';

@DriftAccessor(tables: [ProveedoresTable])
class ProveedoresDao extends DatabaseAccessor<AppDatabase>
    with _$ProveedoresDaoMixin {
  ProveedoresDao(super.db);

  Future<List<ProveedoresTableData>> obtenerTodos() =>
      select(proveedoresTable).get();

  Future<ProveedoresTableData?> obtenerPorId(int id) => (select(
    proveedoresTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertar(ProveedoresTableCompanion proveedor) =>
      into(proveedoresTable).insert(proveedor);

  Future<int> insertarOActualizar(ProveedoresTableCompanion proveedor) =>
      into(proveedoresTable).insertOnConflictUpdate(proveedor);

  Future<bool> actualizar(ProveedoresTableData proveedor) async {
    final exito = await update(proveedoresTable).replace(proveedor);
    return exito;
  }

  Future<bool> eliminar(int id) async {
    final filas = await (delete(
      proveedoresTable,
    )..where((t) => t.id.equals(id))).go();
    return filas > 0;
  }

  Future<List<ProveedoresTableData>> buscarPorNombre(String nombre) =>
      (select(proveedoresTable)..where(
            (t) => t.nombreEmpresa.lower().like('%${nombre.toLowerCase()}%'),
          ))
          .get();
}
