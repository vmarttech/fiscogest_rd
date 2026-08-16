import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/entrada.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_entrada_repository.dart';

class EntradaRepositoryImpl implements IEntradaRepository {
  EntradaRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<void> registrarEntrada(Entrada entrada) async {
    await _db.into(_db.entradasTable).insert(
      EntradasTableCompanion(
        productoId: Value(entrada.productoId),
        cantidad: Value(entrada.cantidad),
        motivo: Value(entrada.motivo),
        usuario: Value(entrada.usuario),
        costoUnitario: Value(entrada.costoUnitario),
        observacion: Value(entrada.observacion),
        fecha: Value(entrada.fecha.millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<List<Entrada>> obtenerHistorialEntradas() async {
    final registros = await _db.select(_db.entradasTable).get();
    return registros.map((fila) => Entrada(
      id: fila.id,
      productoId: fila.productoId,
      cantidad: fila.cantidad,
      motivo: fila.motivo,
      usuario: fila.usuario,
      costoUnitario: fila.costoUnitario,
      observacion: fila.observacion,
      fecha: DateTime.fromMillisecondsSinceEpoch(fila.fecha),
    )).toList();
  }

  @override
  Future<List<Entrada>> obtenerEntradasPorProducto(int productoId) async {
    final registros = await (_db.select(_db.entradasTable)
          ..where((t) => t.productoId.equals(productoId)))
        .get();
    return registros.map((fila) => Entrada(
      id: fila.id,
      productoId: fila.productoId,
      cantidad: fila.cantidad,
      motivo: fila.motivo,
      usuario: fila.usuario,
      costoUnitario: fila.costoUnitario,
      observacion: fila.observacion,
      fecha: DateTime.fromMillisecondsSinceEpoch(fila.fecha),
    )).toList();
  }
}
