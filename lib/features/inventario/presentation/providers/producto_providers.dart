import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/providers/core_providers.dart'; // ✅ Import agregado
import 'package:fiscogest_rd/features/inventario/data/datasources/drift_kardex_datasource.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/producto_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/kardex_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_producto_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';

final driftKardexDatasourceProvider = Provider<DriftKardexDatasource>((ref) {
  return DriftKardexDatasource(ref.watch(databaseProvider));
});

final kardexRepositoryProvider = Provider<IKardexRepository>((ref) {
  return KardexRepositoryImpl(ref.watch(driftKardexDatasourceProvider));
});

final productoRepositoryProvider = Provider<IProductoRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final kardexRepo = ref.watch(kardexRepositoryProvider);
  return ProductoRepositoryImpl(db, kardexRepo);
});

class ProductoController extends StateNotifier<AsyncValue<List<Producto>>> {
  ProductoController(this._repository, this._ref) : super(const AsyncValue.loading()) { // ✅ Agregamos parámetro ref
    cargarProductos();
  }
  final IProductoRepository _repository;
  final Ref _ref; // ✅ Guardamos la referencia para leer proveedores

  Future<void> cargarProductos() async {
    state = const AsyncValue.loading();
    try {
      final productos = await _repository.obtenerProductos();
      state = AsyncValue.data(List.unmodifiable(productos));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> guardar(Producto producto) async {
    try {
      // ✅ Leemos el usuario aquí (capa permitida) y se lo pasamos al repositorio
      final idUsuario = _ref.read(usuarioAutenticadoProvider)!;
      await _repository.guardarProducto(producto, idUsuario);
      await cargarProductos();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> actualizar(Producto producto) async {
    try {
      await _repository.actualizarProducto(producto);
      await cargarProductos();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> eliminar(int id) async {
    try {
      await _repository.eliminarProducto(id);
      await cargarProductos();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// ✅ Actualizamos la creación del controlador para pasar la referencia
final productoControllerProvider = StateNotifierProvider<ProductoController, AsyncValue<List<Producto>>>((ref) {
  return ProductoController(ref.watch(productoRepositoryProvider), ref);
});
