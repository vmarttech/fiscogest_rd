import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/clientes/data/dao/clientes_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cobros_table.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

part 'cuentas_cobrar_dao.g.dart';

@DriftAccessor(tables: [CuentasCobrarTable, CobrosTable, ClientesTable])
class CuentasCobrarDao extends DatabaseAccessor<AppDatabase> with _$CuentasCobrarDaoMixin {
  CuentasCobrarDao(AppDatabase db) : super(db);

  Future<double?> obtenerSaldoPorCliente(int clienteId) async {
    final filas = await (select(cuentasCobrarTable)
      ..where((t) => t.clienteId.equals(clienteId)))
      .get();
    if (filas.isEmpty) return null;
    final saldoTotal = filas.fold<double>(
      0.0,
      (total, fila) => total + fila.saldoPendiente,
    );
    return saldoTotal;
  }

  Future<int> crearCuentaPorVenta({
    required int clienteId,
    required int ventaId,
    required double montoOriginal,
    required DateTime fechaVencimiento,
  }) async {
    final saldoInicial = montoOriginal;
    return into(cuentasCobrarTable).insert(
      CuentasCobrarTableCompanion(
        clienteId: Value(clienteId),
        ventaId: Value(ventaId),
        montoOriginal: Value(montoOriginal),
        montoAbonado: const Value(0.0),
        saldoPendiente: Value(saldoInicial),
        fechaVencimiento: Value(fechaVencimiento),
        estado: const Value(CobrarEstado.pendiente),
      ),
    );
  }

  Future<List<CuentaCobrarConCliente>> listarCuentasPorCobrar({
    CobrarEstado? estado,
    DateTime? vencidasAntes,
  }) async {
    final q = select(cuentasCobrarTable).join([
      innerJoin(clientesTable, clientesTable.id.equalsExp(cuentasCobrarTable.clienteId)),
    ]);

    if (estado != null) {
      q.where(cuentasCobrarTable.estado.equals(estado.name));
    }
    if (vencidasAntes != null) {
      q.where(cuentasCobrarTable.fechaVencimiento.isSmallerThanValue(vencidasAntes));
    }

    q.orderBy([OrderingTerm(expression: cuentasCobrarTable.fechaVencimiento, mode: OrderingMode.desc)]);

    final filas = await q.get();
    return filas.map((f) {
      final cuenta = f.readTable(cuentasCobrarTable);
      final cliente = f.readTable(clientesTable);
      return CuentaCobrarConCliente(
        cuenta: cuenta,
        nombreCliente: cliente.nombre,
      );
    }).toList();
  }
}

class CuentaCobrarConCliente {

  const CuentaCobrarConCliente({
    required this.cuenta,
    required this.nombreCliente,
  });
  final CuentaCobrarData cuenta;
  final String nombreCliente;
}
