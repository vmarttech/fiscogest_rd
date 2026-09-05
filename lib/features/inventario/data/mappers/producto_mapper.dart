import 'package:drift/drift.dart' as drift;
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';

class ProductoDataMapper {
  static Producto toDomain(ProductoData fila) {
    return Producto(
      id: fila.id,
      codigo: fila.codigo,
      codigoBarras: fila.codigoBarras,
      nombre: fila.nombre,
      descripcion: fila.descripcion,
      precioCompra: fila.precioCompra ?? 0.0,
      gastosAsociados: fila.gastosAsociados ?? 0.0,
      precioVenta: fila.precioVenta ?? 0.0,
      margenGanancia: fila.margenGanancia,
      precioMinimo: fila.precioMinimo,
      precioMayorista: fila.precioMayorista,
      precioEspecial: fila.precioEspecial,
      stock: fila.stock,
      stockMinimo: fila.stockMinimo,
      stockMaximo: fila.stockMaximo,
      categoriaId: fila.categoriaId,
      marcaId: fila.marcaId,
      unidadMedidaId: fila.unidadMedidaId,
      activo: fila.activo == 1,
    );
  }

  static ProductosTableCompanion toCompanion(Producto entidad) {
    return ProductosTableCompanion(
      id: entidad.id != null
          ? drift.Value(entidad.id!)
          : const drift.Value.absent(),
      codigo: drift.Value(entidad.codigo),
      codigoBarras: drift.Value(entidad.codigoBarras),
      nombre: drift.Value(entidad.nombre),
      descripcion: drift.Value(entidad.descripcion),
      precioCompra: drift.Value(entidad.precioCompra),
      gastosAsociados: drift.Value(entidad.gastosAsociados),
      precioVenta: drift.Value(entidad.precioVenta),
      margenGanancia: entidad.margenGanancia != null
          ? drift.Value(entidad.margenGanancia!)
          : const drift.Value.absent(),
      precioMinimo: entidad.precioMinimo != null
          ? drift.Value(entidad.precioMinimo!)
          : const drift.Value.absent(),
      precioMayorista: entidad.precioMayorista != null
          ? drift.Value(entidad.precioMayorista!)
          : const drift.Value.absent(),
      precioEspecial: entidad.precioEspecial != null
          ? drift.Value(entidad.precioEspecial!)
          : const drift.Value.absent(),
      stock: drift.Value(entidad.stock),
      stockMinimo: drift.Value(entidad.stockMinimo),
      stockMaximo: drift.Value(entidad.stockMaximo),
      categoriaId: drift.Value(entidad.categoriaId),
      marcaId: drift.Value(entidad.marcaId),
      unidadMedidaId: drift.Value(entidad.unidadMedidaId),
      activo: drift.Value(entidad.activo ? 1 : 0),
    );
  }
}
