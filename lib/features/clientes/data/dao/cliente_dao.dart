import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/clientes/data/dao/clientes_table.dart';

part 'cliente_dao.g.dart';

@DriftAccessor(tables: [ClientesTable])
class ClienteDao extends DatabaseAccessor<AppDatabase> with _$ClienteDaoMixin {
  ClienteDao(super.db);

  Future<List<ClientesTableData>> obtenerTodos() => select(clientesTable).get();

  Future<ClientesTableData?> obtenerPorId(int id) =>
      (select(clientesTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertarOActualizar(ClientesTableCompanion cliente) =>
      into(clientesTable).insertOnConflictUpdate(cliente);

  Future<bool> eliminar(int id) async {
    final filasAfectadas = await (delete(clientesTable)..where((t) => t.id.equals(id))).go();
    return filasAfectadas > 0;
  }
}