import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_pagar_table.dart';

part 'cuentas_pagar_dao.g.dart';

@DriftAccessor(tables: [CuentasPagarTable])
class CuentasPagarDao extends DatabaseAccessor<AppDatabase> with _$CuentasPagarDaoMixin {
  CuentasPagarDao(super.db);

  Future<List<CuentaPagarData>> obtenerTodas() => select(cuentasPagarTable).get();

  Future<CuentaPagarData?> obtenerPorId(int id) =>
      (select(cuentasPagarTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertar(CuentasPagarTableCompanion cuenta) =>
      into(cuentasPagarTable).insert(cuenta);

  Future<bool> actualizarEstado(int id, String estado) async {
    final filas = await (update(cuentasPagarTable)..where((t) => t.id.equals(id)))
        .write(CuentasPagarTableCompanion(estado: Value(estado)));
    return filas > 0;
  }

  Future<List<CuentaPagarData>> listarPorProveedor(int proveedorId) =>
      (select(cuentasPagarTable)..where((t) => t.proveedorId.equals(proveedorId))).get();

  Future<List<CuentaPagarData>> listarPorFiltros({
    DateTime? desde,
    DateTime? hasta,
    int? proveedorId,
    String? estado,
    String? tipoGasto,
  }) {
    final query = select(cuentasPagarTable);
    if (desde != null) query.where((t) => t.fechaEmision.isBiggerOrEqualValue(desde));
    if (hasta != null) query.where((t) => t.fechaEmision.isSmallerOrEqualValue(hasta));
    if (proveedorId != null) query.where((t) => t.proveedorId.equals(proveedorId));
    if (estado != null) query.where((t) => t.estado.equals(estado));
    if (tipoGasto != null) query.where((t) => t.tipoGasto.equals(tipoGasto));
    query.orderBy([(t) => OrderingTerm(expression: t.fechaVencimiento, mode: OrderingMode.asc)]);
    return query.get();
  }
}
