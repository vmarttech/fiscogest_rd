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
    return ProductosTableCompanion(
      id: producto.id != null ? drift.Value(producto.id!) : const drift.Value.absent(),
      codigo: drift.Value(producto.codigo),
      nombre: drift.Value(producto.nombre),
      descripcion: producto.descripcion != null ? drift.Value(producto.descripcion!) : const drift.Value.absent(),
      precioCompra: drift.Value(producto.precioCompra),
      precioVenta: drift.Value(producto.precioVenta),
      stock: drift.Value(producto.stock),
      stockMinimo: drift.Value(producto.stockMinimo),
      categoriaId: producto.categoriaId != null ? drift.Value(producto.categoriaId!) : const drift.Value.absent(),
      marcaId: producto.marcaId != null ? drift.Value(producto.marcaId!) : const drift.Value.absent(),
      unidadMedidaId: producto.unidadId != null ? drift.Value(producto.unidadId!) : const drift.Value.absent(),
      activo: drift.Value(producto.activo),
    );
  }
}
