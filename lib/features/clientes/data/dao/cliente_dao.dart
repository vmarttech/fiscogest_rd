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
    final filasAfectadas = await (delete(
      clientesTable,
    )..where((t) => t.id.equals(id))).go();
    return filasAfectadas > 0;
  }

  Future<List<ClientesTableData>> buscarPorNombre(String nombre) => (select(
    clientesTable,
  )..where((t) => t.nombre.lower().like('%${nombre.toLowerCase()}%'))).get();

  Future<double?> obtenerSaldo(int clienteId) async {
    final registro = await obtenerPorId(clienteId);
    return registro?.saldoPendiente;
  }

  Future<void> actualizarSaldo(
    int clienteId,
    double monto,
    bool esCargo,
  ) async {
    final registro = await obtenerPorId(clienteId);
    if (registro == null) return;
    final saldoActual = registro.saldoPendiente;
    final nuevoSaldo = esCargo ? saldoActual + monto : saldoActual - monto;
    await (update(clientesTable)..where((t) => t.id.equals(clienteId))).write(
      ClientesTableCompanion(saldoPendiente: Value(nuevoSaldo)),
    );
  }
}
