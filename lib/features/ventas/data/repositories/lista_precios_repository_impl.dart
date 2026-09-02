import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/lista_precios.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_lista_precios_repository.dart';
import 'package:drift/drift.dart';

class ListaPreciosRepositoryImpl implements IListaPreciosRepository {
  const ListaPreciosRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<ListaPrecios?> obtenerPorProductoId(int productoId) async {
    final query = _db.select(_db.productosTable)
      ..where((t) => t.id.equals(productoId));
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
    await (_db.update(
      _db.productosTable,
    )..where((t) => t.id.equals(listaPrecios.productoId))).write(
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
  Future<void> actualizarPrecioVenta(int productoId, double nuevoPrecio) async {
    await (_db.update(_db.productosTable)
          ..where((t) => t.id.equals(productoId)))
        .write(ProductosTableCompanion(precioVenta: Value(nuevoPrecio)));
  }
}
