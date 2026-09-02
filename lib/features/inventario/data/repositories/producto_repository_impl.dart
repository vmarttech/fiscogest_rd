import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_producto_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';
import 'package:fiscogest_rd/features/inventario/data/mappers/producto_mapper.dart';

class ProductoRepositoryImpl implements IProductoRepository {
  ProductoRepositoryImpl(this._db, this._kardexRepo);

  final AppDatabase _db;
  final IKardexRepository _kardexRepo;

  @override
  Future<List<Producto>> obtenerProductos() async {
    final results = await _db.select(_db.productosTable).get();
    return results.map(ProductoDataMapper.toDomain).toList();
  }

  @override
  Future<Producto?> obtenerProductoPorId(int id) async {
    final query = _db.select(_db.productosTable)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return ProductoDataMapper.toDomain(row);
  }

  @override
  Future<Producto?> obtenerProductoPorCodigo(String codigo) async {
    final query = _db.select(_db.productosTable)
      ..where((t) => t.codigo.equals(codigo));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return ProductoDataMapper.toDomain(row);
  }

  @override
  Future<int> guardarProducto(Producto producto, int idUsuario) async {
    return await _db.transaction(() async {
      final idGenerado = await _db
          .into(_db.productosTable)
          .insert(ProductoDataMapper.toCompanion(producto));
      await _kardexRepo.registrarMovimiento(
        Kardex(
          id: null,
          productoId: idGenerado,
          tipoMovimiento: TipoMovimiento.entrada,
          cantidad: producto.stock ?? 0.0,
          saldoAnterior: 0,
          saldoNuevo: producto.stock ?? 0.0,
          costoUnitario: producto.precioCompra,
          totalMovimiento: producto.precioCompra * (producto.stock ?? 0.0),
          fechaMovimiento: DateTime.now(),
          documentoReferencia: 'INGRESO INICIAL',
          observacion: 'Registro al crear producto',
          usuarioId: idUsuario,
        ),
      );
      return idGenerado;
    });
  }

  @override
  Future<bool> actualizarProducto(Producto producto) async {
    if (producto.id == null) return false;
    final rowsAffected =
        await (_db.update(_db.productosTable)
              ..where((t) => t.id.equals(producto.id!)))
            .write(ProductoDataMapper.toCompanion(producto));
    return rowsAffected > 0;
  }

  @override
  Future<bool> eliminarProducto(int id) async {
    final rowsAffected = await (_db.delete(
      _db.productosTable,
    )..where((t) => t.id.equals(id))).go();
    return rowsAffected > 0;
  }
}
