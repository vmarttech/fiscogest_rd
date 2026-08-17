import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cobros_table.dart';

part 'cuentas_cobrar_dao.g.dart';

@DriftAccessor(tables: [CuentasCobrarTable, CobrosTable])
class CuentasCobrarDao extends DatabaseAccessor<AppDatabase> with _$CuentasCobrarDaoMixin {
  CuentasCobrarDao(super.db);

  Future<List<CuentaCobrarData>> obtenerTodas() => select(cuentasCobrarTable).get();

  Future<CuentaCobrarData?> obtenerPorId(int id) =>
      (select(cuentasCobrarTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<CuentaCobrarData?> obtenerPorVenta(int ventaId) =>
      (select(cuentasCobrarTable)..where((t) => t.ventaId.equals(ventaId))).getSingleOrNull();

  Future<int> insertar(CuentasCobrarTableCompanion cuenta) =>
      into(cuentasCobrarTable).insert(cuenta);

  Future<bool> actualizarSaldo(int id, double montoAbonado, double saldoPendiente, String estado) async {
    final filas = await (update(cuentasCobrarTable)..where((t) => t.id.equals(id)))
        .write(CuentasCobrarTableCompanion(
          montoAbonado: Value(montoAbonado),
          saldoPendiente: Value(saldoPendiente),
          estado: Value(estado),
        ));
    return filas > 0;
  }

  Future<List<CuentaCobrarData>> listarPorCliente(int clienteId) =>
      (select(cuentasCobrarTable)..where((t) => t.clienteId.equals(clienteId))).get();

  Future<List<CuentaCobrarData>> listarVencidas(DateTime fechaLimite) =>
      (select(cuentasCobrarTable)
        ..where((t) => t.fechaVencimiento.isSmallerThanValue(fechaLimite))
        ..where((t) => t.estado.isNotIn(['Pagado']))
      ).get();

  Future<List<CobroData>> obtenerCobrosPorCuenta(int cuentaCobrarId) =>
      (select(cobrosTable)..where((t) => t.cuentaCobrarId.equals(cuentaCobrarId))
        ..orderBy([(t) => OrderingTerm(expression: t.fecha, mode: OrderingMode.desc)])
      ).get();

  Future<int> registrarCobro(CobrosTableCompanion cobro) =>
      into(cobrosTable).insert(cobro);

  Future<bool> aplicarCobro(int cuentaId, CobrosTableCompanion cobro, double nuevoSaldo, double nuevoAbonado, String nuevoEstado) async {
    return transaction(() async {
      await into(cobrosTable).insert(cobro);
      final filas = await (update(cuentasCobrarTable)..where((t) => t.id.equals(cuentaId)))
          .write(CuentasCobrarTableCompanion(
            saldoPendiente: Value(nuevoSaldo),
            montoAbonado: Value(nuevoAbonado),
            estado: Value(nuevoEstado),
          ));
      return filas > 0;
    });
  }
}
