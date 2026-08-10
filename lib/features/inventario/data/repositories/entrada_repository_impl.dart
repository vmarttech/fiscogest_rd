import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/entrada.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_entrada_repository.dart';

class EntradaRepositoryImpl implements IEntradaRepository {
  EntradaRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<void> registrarEntrada(Entrada entrada) async {
    // ✅ SOLO PERSISTENCIA —SIN LÓGICA DE NEGOCIO
    await _db.into(_db.entradasTable).insert(
      EntradasTableCompanion.insert(
        productoId: entrada.productoId,
        cantidad: entrada.cantidad,
        motivo: entrada.motivo,
        usuario: entrada.usuario,
        fecha: entrada.fecha,
      ),
    );
  }

  @override
  Future<List<Entrada>> obtenerHistorialEntradas() async {
    final query = await _db.select(_db.entradasTable).get();
    return query.map((row) => Entrada(
      id: row.id,
      productoId: row.productoId,
      cantidad: row.cantidad,
      motivo: row.motivo,
      usuario: row.usuario,
      fecha: row.fecha,
    )).toList();
  }

  @override
  Future<List<Entrada>> obtenerEntradasPorProducto(int productoId) async {
    final query = await (_db.select(_db.entradasTable)
      ..where((e) => e.productoId.equals(productoId)))
      .get();
    return query.map((row) => Entrada(
      id: row.id,
      productoId: row.productoId,
      cantidad: row.cantidad,
      motivo: row.motivo,
      usuario: row.usuario,
      fecha: row.fecha,
    )).toList();
  }
}