import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../data/repositories/producto_repository_impl.dart';
import '../../domain/entities/producto.dart';
import '../../domain/interfaces/i_producto_repository.dart';

// Provider global de la base de datos
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Provider del Repositorio de Productos
final productoRepositoryProvider = Provider<IProductoRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductoRepositoryImpl(db);
});

// Notifier / StateNotifier para la gestión de la lista de productos
class ProductoController extends StateNotifier<AsyncValue<List<Producto>>> {
  final IProductoRepository _repository;

  ProductoController(this._repository) : super(const AsyncValue.loading()) {
    cargarProductos();
  }

  Future<void> cargarProductos() async {
    state = const AsyncValue.loading();
    try {
      final productos = await _repository.obtenerProductos();
      state = AsyncValue.data(productos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> guardar(Producto producto) async {
    await _repository.guardarProducto(producto);
    await cargarProductos();
  }

  Future<void> actualizar(Producto producto) async {
    await _repository.actualizarProducto(producto);
    await cargarProductos();
  }

  Future<void> eliminar(int id) async {
    await _repository.eliminarProducto(id);
    await cargarProductos();
  }
}

// Provider del controlador de productos
final productoControllerProvider = StateNotifierProvider<ProductoController, AsyncValue<List<Producto>>>((ref) {
  final repository = ref.watch(productoRepositoryProvider);
  return ProductoController(repository);
});
