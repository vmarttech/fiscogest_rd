import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cobros_table.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
part 'cuentas_cobrar_dao.g.dart';

@DriftAccessor(tables: [CuentasCobrarTable, CobrosTable])
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
}
