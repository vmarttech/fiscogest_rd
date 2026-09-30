import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/categoria_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/categoria.dart';
import 'package:fiscogest_rd/features/inventario/domain/repositories/categoria_repository.dart';

final categoriaRepositoryProvider = Provider<CategoriaRepository>((ref) {
  return CategoriaRepositoryImpl(ref.watch(databaseProvider));
});

final categoriaControllerProvider =
    AsyncNotifierProvider<CategoriaController, List<Categoria>>(() {
      return CategoriaController();
    });

class CategoriaController extends AsyncNotifier<List<Categoria>> {
  late final CategoriaRepository _repo;

  @override
  Future<List<Categoria>> build() async {
    _repo = ref.read(categoriaRepositoryProvider);
    return _repo.obtenerTodos();
  }

  Future<void> guardar(Categoria categoria) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.guardar(categoria);
      return _repo.obtenerTodos();
    });
  }

  Future<void> actualizar(Categoria categoria) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.actualizar(categoria);
      return _repo.obtenerTodos();
    });
  }

  Future<void> eliminar(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.eliminar(id);
      return _repo.obtenerTodos();
    });
  }
}
