import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
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
  ProductoController(this._repository) : super(const AsyncValue.loading()) {
    cargarProductos();
  }
  final IProductoRepository _repository;

  Future<void> cargarProductos() async {
    state = const AsyncValue.loading();
    try {
      final productos = await _repository.obtenerProductos();
      // ✅ FUERZA NUEVA REFERENCIA PARA QUE EL WIDGET DETECTE EL CAMBIO
      state = AsyncValue.data(List.unmodifiable(productos));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> guardar(Producto producto) async {
    try {
      await _repository.guardarProducto(producto);
      await cargarProductos(); // ✅ YA ESTABA, PERO ASEGURAMOS LA NUEVA LISTA
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

final productoControllerProvider = StateNotifierProvider<ProductoController, AsyncValue<List<Producto>>>((ref) {
  return ProductoController(ref.watch(productoRepositoryProvider));
});