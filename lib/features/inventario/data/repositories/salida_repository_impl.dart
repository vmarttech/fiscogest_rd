import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/salida.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_salida_repository.dart';

class SalidaRepositoryImpl implements ISalidaRepository {
  SalidaRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<void> registrarSalida(Salida salida) async {
    await _db.into(_db.salidasTable).insert(
      SalidasTableCompanion(
        productoId: Value(salida.productoId),
        cantidad: Value(salida.cantidad),
        motivo: Value(salida.motivo),
        usuario: Value(salida.usuario),
        observacion: Value(salida.observacion),
        fecha: Value(salida.fecha.millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<List<Salida>> obtenerHistorialSalidas() async {
    final registros = await _db.select(_db.salidasTable).get();
    return registros.map((fila) => Salida(
      id: fila.id,
      productoId: fila.productoId,
      cantidad: fila.cantidad,
      motivo: fila.motivo,
      usuario: fila.usuario,
      observacion: fila.observacion,
      fecha: DateTime.fromMillisecondsSinceEpoch(fila.fecha),
    )).toList();
  }

  @override
  Future<List<Salida>> obtenerSalidasPorProducto(int productoId) async {
    final registros = await (_db.select(_db.salidasTable)
          ..where((t) => t.productoId.equals(productoId)))
        .get();
    return registros.map((fila) => Salida(
      id: fila.id,
      productoId: fila.productoId,
      cantidad: fila.cantidad,
      motivo: fila.motivo,
      usuario: fila.usuario,
      observacion: fila.observacion,
      fecha: DateTime.fromMillisecondsSinceEpoch(fila.fecha),
    )).toList();
  }
}
