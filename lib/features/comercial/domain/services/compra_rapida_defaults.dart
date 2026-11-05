import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_producto_repository.dart';
import 'package:fiscogest_rd/features/proveedores/domain/entities/proveedor.dart';
import 'package:fiscogest_rd/features/proveedores/domain/repositories/i_proveedor_repository.dart';

/// Valores por defecto para el flujo de compra rápida (modo simplificado).
class CompraRapidaDefaults {
  CompraRapidaDefaults({
    required this.proveedorRepo,
    required this.productoRepo,
  });

  final IProveedorRepository proveedorRepo;
  final IProductoRepository productoRepo;

  static const nombreProveedorGenerico = 'Compra rápida';

  Future<Proveedor> obtenerOCrearProveedorGenerico() async {
    final lista = await proveedorRepo.obtenerProveedores();
    for (final p in lista) {
      if (p.nombreEmpresa.trim().toLowerCase() ==
          nombreProveedorGenerico.toLowerCase()) {
        return p;
      }
    }
    final nuevo = Proveedor(
      nombreEmpresa: nombreProveedorGenerico,
      estado: 'Activo',
      fechaCreacion: DateTime.now(),
    );
    final id = await proveedorRepo.guardarProveedor(nuevo);
    return nuevo.copyWith(id: id);
  }

  Future<Producto> obtenerOCrearProducto({
    required String nombre,
    required double costo,
    required int usuarioId,
    required List<Producto> catalogoActual,
  }) async {
    final q = nombre.trim().toLowerCase();
    if (q.isEmpty) {
      throw StateError('El nombre del producto es obligatorio');
    }

    for (final p in catalogoActual) {
      if (p.nombre.trim().toLowerCase() == q) return p;
    }
    for (final p in catalogoActual) {
      if (p.nombre.trim().toLowerCase().contains(q)) return p;
    }

    int marcaId = 1;
    int categoriaId = 1;
    int unidadMedidaId = 1;
    if (catalogoActual.isNotEmpty) {
      final seed = catalogoActual.first;
      marcaId = seed.marcaId;
      categoriaId = seed.categoriaId;
      unidadMedidaId = seed.unidadMedidaId;
    }

    final codigo =
        'CR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final nuevo = Producto(
      codigo: codigo,
      nombre: nombre.trim(),
      precioCompra: costo,
      precioVenta: costo,
      costoPromedio: costo,
      stock: 0,
      categoriaId: categoriaId,
      marcaId: marcaId,
      unidadMedidaId: unidadMedidaId,
      activo: true,
    );

    final id = await productoRepo.guardarProducto(nuevo, usuarioId);
    return nuevo.copyWith(id: id);
  }
}
