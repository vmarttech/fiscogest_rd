import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/proveedores/data/dao/proveedores_table.dart';

part 'proveedores_dao.g.dart';

@DriftAccessor(tables: [ProveedoresTable])
class ProveedoresDao extends DatabaseAccessor<AppDatabase> with _$ProveedoresDaoMixin {
  ProveedoresDao(super.db);

  Future<List<ProveedorData>> obtenerTodos() => select(proveedoresTable).get();

  Future<ProveedorData?> obtenerPorId(int id) =>
      (select(proveedoresTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertar(ProveedoresTableCompanion proveedor) =>
      into(proveedoresTable).insert(proveedor);

  Future<int> insertarOActualizar(ProveedoresTableCompanion proveedor) =>
      into(proveedoresTable).insertOnConflictUpdate(proveedor);

  Future<bool> actualizar(ProveedorData proveedor) async {
    final bool exito = await update(proveedoresTable).replace(proveedor);
    return exito;
  }

  Future<bool> eliminar(int id) async {
    final int filas = await (delete(proveedoresTable)..where((t) => t.id.equals(id))).go();
    return filas > 0;
  }

  Future<List<ProveedorData>> buscarPorNombre(String nombre) =>
      (select(proveedoresTable)
        ..where((t) => t.nombreEmpresa.lower().like('%${nombre.toLowerCase()}%'))
      ).get();
}
