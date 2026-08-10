import 'package:drift/drift.dart' as drift;
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';

class ProductoDataMapper {
  static Producto toDomain(ProductosTableData row) {
    return Producto(
      id: row.id,
      codigo: row.codigo,
      nombre: row.nombre,
      descripcion: row.descripcion,
      precioCompra: row.precioCompra,
      precioVenta: row.precioVenta,
      stock: row.stock,
      stockMinimo: row.stockMinimo,
      categoriaId: row.categoriaId,
      marcaId: row.marcaId,
      unidadId: row.unidadMedidaId,
      activo: row.activo,
    );
  }

 static ProductosTableCompanion toCompanion(Producto producto) {
  // ✅ Declara la variable AQUÍ, fuera del constructor
  final _id = producto.id;

  return ProductosTableCompanion(
    id: _id != null ? drift.Value(_id) : const drift.Value.absent(),
    codigo: drift.Value(producto.codigo),
    nombre: drift.Value(producto.nombre),
      descripcion: drift.Value(producto.descripcion),
      precioCompra: drift.Value(producto.precioCompra),
      precioVenta: drift.Value(producto.precioVenta),
      stock: drift.Value(producto.stock),
      stockMinimo: drift.Value(producto.stockMinimo),
      categoriaId: drift.Value(producto.categoriaId),
      marcaId: drift.Value(producto.marcaId),
      unidadMedidaId: drift.Value(producto.unidadId),
      activo: drift.Value(producto.activo),
    );
  }
}