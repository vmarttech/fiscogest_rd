import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_producto_repository.dart';

class ProductoRepositoryImpl implements IProductoRepository {
  ProductoRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<void> actualizarCostoProducto({
    required int productoId,
    required double costoUnitario,
    required double cantidadAnterior,
    required double cantidadMovimiento,
  }) async {
    final registro = await (_db.select(_db.productosTable)
          ..where((fila) => fila.id.equals(productoId))
          ..limit(1))
        .getSingleOrNull();

    final double costoActualAnterior = registro?.precioCompra ?? 0.0;
    final double existenciaNueva = cantidadAnterior + cantidadMovimiento;

    double nuevoCosto = costoUnitario;
    if (cantidadAnterior > 0) {
      final double costoTotalAnterior = cantidadAnterior * costoActualAnterior;
      final double costoTotalEntrada = cantidadMovimiento * costoUnitario;
      nuevoCosto = (costoTotalAnterior + costoTotalEntrada) / existenciaNueva;
    }

    await (_db.update(_db.productosTable)
          ..where((fila) => fila.id.equals(productoId)))
        .write(ProductosTableCompanion(
          precioCompra: Value(nuevoCosto),
        ));
  }
}
