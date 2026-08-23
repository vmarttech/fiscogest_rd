import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_table.dart';
import 'package:fiscogest_rd/features/clientes/data/dao/clientes_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_detalle_table.dart';

part 'ventas_dao.g.dart';

class VentaConCliente {

  VentaConCliente({required this.venta, this.nombreCliente});
  final VentaData venta;
  final String? nombreCliente;
}

@DriftAccessor(tables: [VentasTable, ClientesTable, VentasDetalleTable])
class VentasDao extends DatabaseAccessor<AppDatabase> with _$VentasDaoMixin {
  VentasDao(AppDatabase db) : super(db);

  Future<List<VentaConCliente>> listarVentas({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  }) async {
    final v = ventasTable;
    final c = clientesTable;
    final query = select(v).join([
      leftOuterJoin(c, v.clienteId.equalsExp(c.id)),
    ]);
    if (desde != null) {
      query.where(v.fecha.isBiggerOrEqualValue(desde));
    }
    if (hasta != null) {
      query.where(v.fecha.isSmallerOrEqualValue(hasta));
    }
    if (clienteId != null) {
      query.where(v.clienteId.equals(clienteId));
    }
    if (usuarioId != null) {
      query.where(v.usuarioId.equals(usuarioId));
    }
    query.orderBy([OrderingTerm.desc(v.fecha)]);
    final resultados = await query.get();
    return resultados.map((fila) {
      final venta = fila.readTable(v);
      final cliente = fila.readTableOrNull(c);
      return VentaConCliente(
        venta: venta,
        nombreCliente: cliente?.nombre,
      );
    }).toList();
  }

  Future<VentaData?> obtenerVentaPorId(int ventaId) async {
    return await (select(ventasTable)..where((VentasTable t) => t.id.equals(ventaId)))
        .getSingleOrNull();
  }

  Future<List<VentaDetalleData>> listarDetallePorVenta(int ventaId) async {
    return await (select(ventasDetalleTable)
          ..where((VentasDetalleTable t) => t.ventaId.equals(ventaId)))
        .get();
  }

  Future<int> insertarVenta(VentasTableCompanion venta) async {
    return await into(ventasTable).insert(venta);
  }

  Future<bool> actualizarVenta(int ventaId, VentasTableCompanion venta) async {
    final filasAfectadas = await (update(ventasTable)
          ..where((VentasTable t) => t.id.equals(ventaId)))
        .write(venta);
    return filasAfectadas > 0;
  }
}
