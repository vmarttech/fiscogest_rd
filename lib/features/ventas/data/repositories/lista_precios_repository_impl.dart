import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/lista_precios.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_lista_precios_repository.dart';
import 'package:drift/drift.dart';

class ListaPreciosRepositoryImpl implements IListaPreciosRepository {
  const ListaPreciosRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<ListaPrecios?> obtenerPorProductoId(String productoId) async {
    final int id = int.parse(productoId);
    final query = _db.select(_db.productosTable)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return ListaPrecios(
      productoId: productoId,
      precioVenta: row.precioVenta ?? 0.0,
      margenGanancia: row.margenGanancia,
      precioMinimo: row.precioMinimo,
      precioMayorista: row.precioMayorista,
      precioEspecial: row.precioEspecial,
    );
  }

  @override
  Future<void> guardar(ListaPrecios listaPrecios) async {
    final int id = int.parse(listaPrecios.productoId);
    await (_db.update(_db.productosTable)
      ..where((t) => t.id.equals(id))).write(
        ProductosTableCompanion(
          precioVenta: Value(listaPrecios.precioVenta),
          margenGanancia: Value(listaPrecios.margenGanancia),
          precioMinimo: Value(listaPrecios.precioMinimo),
          precioMayorista: Value(listaPrecios.precioMayorista),
          precioEspecial: Value(listaPrecios.precioEspecial),
        ),
      );
  }

  @override
  Future<void> actualizarPrecioVenta(String productoId, double nuevoPrecio) async {
    final int id = int.parse(productoId);
    await (_db.update(_db.productosTable)
      ..where((t) => t.id.equals(id))).write(
        ProductosTableCompanion(precioVenta: Value(nuevoPrecio)),
      );
  }
}
