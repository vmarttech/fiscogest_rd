import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/salida.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_salida_repository.dart';

class SalidaRepositoryImpl implements ISalidaRepository {
  SalidaRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<void> registrarSalida(Salida salida) async {
    // ✅ SOLO PERSISTENCIA —SIN LÓGICA DE NEGOCIO
    await _db.into(_db.salidasTable).insert(
      SalidasTableCompanion.insert(
        productoId: salida.productoId,
        cantidad: salida.cantidad,
        motivo: salida.motivo,
        usuario: salida.usuario,
        fecha: salida.fecha,
      ),
    );
  }

  @override
  Future<List<Salida>> obtenerHistorialSalidas() async {
    final registros = await _db.select(_db.salidasTable).get();
    return registros.map((r) => Salida(
      id: r.id,
      productoId: r.productoId,
      cantidad: r.cantidad,
      motivo: r.motivo,
      usuario: r.usuario,
      fecha: r.fecha,
    )).toList();
  }

  @override
  Future<List<Salida>> obtenerSalidasPorProducto(int productoId) async {
    final registros = await (_db.select(_db.salidasTable)
      ..where((s) => s.productoId.equals(productoId)))
      .get();
    return registros.map((r) => Salida(
      id: r.id,
      productoId: r.productoId,
      cantidad: r.cantidad,
      motivo: r.motivo,
      usuario: r.usuario,
      fecha: r.fecha,
    )).toList();
  }
}