import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_pagar_table.dart';
// ignore: unused_import — necesario para el join con ProveedoresTable
import 'package:fiscogest_rd/features/proveedores/data/dao/proveedores_table.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

part 'cuentas_pagar_dao.g.dart';

@DriftAccessor(tables: [CuentasPagarTable])
class CuentasPagarDao extends DatabaseAccessor<AppDatabase>
    with _$CuentasPagarDaoMixin {
  CuentasPagarDao(super.db);

  Future<List<CuentaPagarConProveedor>> listarCuentasPorPagar({
    PagarEstado? estado,
  }) async {
    final q = select(cuentasPagarTable).join([
      innerJoin(
        proveedoresTable,
        proveedoresTable.id.equalsExp(cuentasPagarTable.proveedorId),
      ),
    ]);

    if (estado != null) {
      q.where(cuentasPagarTable.estado.equals(estado.name));
    }

    final registros = await q.get();
    return registros.map((fila) {
      final cuenta = fila.readTable(cuentasPagarTable);
      final proveedor = fila.readTable(proveedoresTable);
      return CuentaPagarConProveedor(
        cuenta: cuenta,
        nombreProveedor: proveedor.nombreEmpresa,
      );
    }).toList();
  }
}

class CuentaPagarConProveedor {
  const CuentaPagarConProveedor({
    required this.cuenta,
    required this.nombreProveedor,
  });
  final CuentaPagarData cuenta;
  final String nombreProveedor;
}
