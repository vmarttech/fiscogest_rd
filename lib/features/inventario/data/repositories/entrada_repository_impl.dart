import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/entrada.dart';
import '../../domain/interfaces/i_entrada_repository.dart';

class EntradaRepositoryImpl implements IEntradaRepository {
  final AppDatabase _db;

  EntradaRepositoryImpl(this._db);

  @override
  Future<void> registrarEntrada(Entrada entrada) async {
    await _db.transaction(() async {
      // 1. Insertar el registro en el historial de entradas
      await _db.into(_db.entradasTable).insert(
            EntradasTableCompanion.insert(
              productoId: entrada.productoId,
              cantidad: entrada.cantidad,
              motivo: entrada.motivo,
              usuario: entrada.usuario,
              fecha: entrada.fecha,
            ),
          );

      // 2. Obtener el producto actual para sumar el stock
      final producto = await (_db.select(_db.productosTable)
            ..where((p) => p.id.equals(entrada.productoId)))
          .getSingle();

      // 3. Actualizar automáticamente las existencias sumando la nueva cantidad
      final nuevoStock = producto.stock + entrada.cantidad;
      await (_db.update(_db.productosTable)
            ..where((p) => p.id.equals(entrada.productoId)))
          .write(
            ProductosTableCompanion(
              stock: Value(nuevoStock),
            ),
          );
    });
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
