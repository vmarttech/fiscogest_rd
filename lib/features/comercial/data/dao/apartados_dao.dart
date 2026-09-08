import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_detalle_table.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

part 'apartados_dao.g.dart';

@DriftAccessor(tables: [ApartadosTable, ApartadosDetalleTable])
class ApartadosDao extends DatabaseAccessor<AppDatabase> with _$ApartadosDaoMixin {
  ApartadosDao(super.db);

  Future<List<Map<String, dynamic>>> listarApartados() async {
    final query = select(apartadosTable)
      ..orderBy([(ApartadosTable t) => OrderingTerm(expression: t.fechaReserva, mode: OrderingMode.desc)]);
    final List<ApartadoData> resultados = await query.get();
    return resultados.map((ApartadoData a) => a.toJson()).toList();
  }

  Future<int> insertarApartado(ApartadosTableCompanion apartado) async {
    return into(apartadosTable).insert(apartado);
  }

  Future<int> registrarApartadoCompleto({
    required int clienteId,
    required DateTime fechaReserva,
    required DateTime fechaLimite,
    required double montoTotal,
    required double montoAbonado,
    required double saldoPendiente,
    required ApartadoEstado estado,
  }) async {
    return await into(apartadosTable).insert(
      ApartadosTableCompanion.insert(
        clienteId: clienteId,
        fechaReserva: fechaReserva,
        fechaLimite: fechaLimite,
        montoTotal: montoTotal,
        montoAbonado: Value(montoAbonado),
        saldoPendiente: saldoPendiente,
        estado: Value(estado),
      ),
    );
  }

  Future<int> insertarDetalle({
    required int apartadoId,
    required int productoId,
    required double cantidad,
    required double precioUnitario,
    required double subtotal,
  }) async {
    return await into(apartadosDetalleTable).insert(
      ApartadosDetalleTableCompanion.insert(
        apartadoId: apartadoId,
        productoId: productoId,
        cantidad: cantidad,
        precioUnitario: precioUnitario,
        subtotal: subtotal,
      ),
    );
  }

  Future<bool> actualizarSaldo(int apartadoId, double montoAbonado, double saldoPendiente) async {
    final filasAfectadas = await (update(apartadosTable)
      ..where((ApartadosTable t) => t.id.equals(apartadoId)))
      .write(ApartadosTableCompanion(
        montoAbonado: Value(montoAbonado),
        saldoPendiente: Value(saldoPendiente),
      ));
    return filasAfectadas > 0;
  }

  Future<bool> cambiarEstado(int apartadoId, ApartadoEstado estado) async {
    final filasAfectadas = await (update(apartadosTable)
      ..where((ApartadosTable t) => t.id.equals(apartadoId)))
      .write(ApartadosTableCompanion(estado: Value(estado)));
    return filasAfectadas > 0;
  }

  Future<ApartadoData?> buscarPorId(int apartadoId) async {
    return (select(apartadosTable)
      ..where((ApartadosTable t) => t.id.equals(apartadoId))).getSingleOrNull();
  }

  Future<List<dynamic>> listarDetalles(int apartadoId) async {
    return (select(apartadosDetalleTable)
      ..where((t) => t.apartadoId.equals(apartadoId))).get();
  }
}
