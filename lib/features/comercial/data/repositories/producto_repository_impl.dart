import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_producto_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';

class ProductoRepositoryImpl extends IProductoRepository {
  ProductoRepositoryImpl(this.db);

  final AppDatabase db;

  @override
  Future<void> actualizarCostoProducto({
    required int productoId,
    required double costoUnitario,
    required double cantidadAnterior,
    required double cantidadMovimiento,
  }) async {}

  @override
  Future<List<Producto>> obtenerProductos() async {
    final filas = await db.select(db.productosTable).get();
    return filas
        .map(
          (p) => Producto(
            id: p.id,
            codigo: p.codigo,
            codigoBarras: p.codigoBarras,
            nombre: p.nombre,
            descripcion: p.descripcion,
            precioCompra: p.precioCompra ?? 0.0,
            gastosAsociados: p.gastosAsociados ?? 0.0,
            precioVenta: p.precioVenta ?? 0.0,
            margenGanancia: p.margenGanancia,
            precioMinimo: p.precioMinimo,
            precioMayorista: p.precioMayorista,
            precioEspecial: p.precioEspecial,
            fechaInicioOferta: null,
            fechaFinOferta: null,
            costoPromedio: 0.0,
            stock: p.stock,
            stockMinimo: p.stockMinimo,
            stockMaximo: p.stockMaximo,
            categoriaId: p.categoriaId,
            marcaId: p.marcaId,
            unidadMedidaId: p.unidadMedidaId,
            activo: p.activo == 1,
          ),
        )
        .toList();
  }

  @override
  Future<int> guardarProducto(Producto producto, int idUsuario) async {
    return await db
        .into(db.productosTable)
        .insert(
          ProductosTableCompanion.insert(
            codigo: producto.codigo,
            codigoBarras: Value(producto.codigoBarras),
            nombre: producto.nombre,
            descripcion: Value(producto.descripcion),
            precioCompra: Value(producto.precioCompra),
            gastosAsociados: Value(producto.gastosAsociados),
            precioVenta: Value(producto.precioVenta),
            margenGanancia: Value(producto.margenGanancia),
            precioMinimo: Value(producto.precioMinimo),
            precioMayorista: Value(producto.precioMayorista),
            precioEspecial: Value(producto.precioEspecial),
            stock: Value(producto.stock),
            stockMinimo: Value(producto.stockMinimo),
            stockMaximo: Value(producto.stockMaximo),
            categoriaId: producto.categoriaId,
            marcaId: producto.marcaId,
            unidadMedidaId: producto.unidadMedidaId,
            activo: Value(producto.activo ? 1 : 0),
          ),
        );
  }

  @override
  Future<void> actualizarProducto(Producto producto) async {
    final pid = producto.id;
    if (pid == null) return;
    await (db.update(
      db.productosTable,
    )..where((p) => p.id.equals(pid))).replace(
      ProductosTableCompanion(
        id: Value(pid),
        codigo: Value(producto.codigo),
        codigoBarras: Value(producto.codigoBarras),
        nombre: Value(producto.nombre),
        descripcion: Value(producto.descripcion),
        precioCompra: Value(producto.precioCompra),
        gastosAsociados: Value(producto.gastosAsociados),
        precioVenta: Value(producto.precioVenta),
        margenGanancia: Value(producto.margenGanancia),
        precioMinimo: Value(producto.precioMinimo),
        precioMayorista: Value(producto.precioMayorista),
        precioEspecial: Value(producto.precioEspecial),
        stock: Value(producto.stock),
        stockMinimo: Value(producto.stockMinimo),
        stockMaximo: Value(producto.stockMaximo),
        categoriaId: Value(producto.categoriaId),
        marcaId: Value(producto.marcaId),
        unidadMedidaId: Value(producto.unidadMedidaId),
        activo: Value(producto.activo ? 1 : 0),
      ),
    );
  }

  @override
  Future<void> eliminarProducto(int id) async {
    await (db.delete(db.productosTable)..where((p) => p.id.equals(id))).go();
  }
}
