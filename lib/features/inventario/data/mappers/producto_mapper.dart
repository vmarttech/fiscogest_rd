import 'package:drift/drift.dart' as drift;
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';

class ProductoDataMapper {
  // ✅ Nombre CORRECTO: ProductoData (igual generado por Drift)
  static Producto toDomain(ProductoData fila) {
    return Producto(
      id: fila.id,
      codigo: fila.codigo,
      codigoBarras: fila.codigoBarras,
      nombre: fila.nombre,
      descripcion: fila.descripcion,
      precioCompra: fila.precioCompra ?? 0.0,
      precioVenta: fila.precioVenta ?? 0.0,
      stock: fila.stock,
      stockMinimo: fila.stockMinimo,
      // ✅ Agregados campos que faltaban y generaban error
      stockMaximo: fila.stockMaximo,
      categoriaId: fila.categoriaId,
      marcaId: fila.marcaId,
      unidadMedidaId: fila.unidadMedidaId,
      // ✅ Conversión segura entero ↔ booleano
      activo: fila.activo == 1,
    );
  }

  static ProductosTableCompanion toCompanion(Producto entidad) {
    return ProductosTableCompanion(
      id: entidad.id != null ? drift.Value(entidad.id!) : const drift.Value.absent(),
      codigo: drift.Value(entidad.codigo),
      codigoBarras: drift.Value(entidad.codigoBarras),
      nombre: drift.Value(entidad.nombre),
      descripcion: drift.Value(entidad.descripcion),
      precioCompra: drift.Value(entidad.precioCompra),
      precioVenta: drift.Value(entidad.precioVenta),
      stock: drift.Value(entidad.stock),
      stockMinimo: drift.Value(entidad.stockMinimo),
      // ✅ Completos y declarados
      stockMaximo: drift.Value(entidad.stockMaximo),
      categoriaId: drift.Value(entidad.categoriaId),
      marcaId: drift.Value(entidad.marcaId),
      unidadMedidaId: drift.Value(entidad.unidadMedidaId),
      activo: drift.Value(entidad.activo ? 1 : 0),
    );
  }
}
