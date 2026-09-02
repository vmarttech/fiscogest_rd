import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/marca_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/marca.dart';
import 'package:fiscogest_rd/features/inventario/domain/repositories/marca_repository.dart';

final marcaRepositoryProvider = Provider<MarcaRepository>((ref) {
  return MarcaRepositoryImpl(ref.watch(databaseProvider));
});

final marcaControllerProvider =
    AsyncNotifierProvider<MarcaController, List<Marca>>(() {
      return MarcaController();
    });

class MarcaController extends AsyncNotifier<List<Marca>> {
  late final MarcaRepository _repo;

  @override
  Future<List<Marca>> build() async {
    _repo = ref.read(marcaRepositoryProvider);
    return _repo.obtenerTodos();
  }

  Future<void> guardar(Marca marca) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.guardar(marca);
      return _repo.obtenerTodos();
    });
  }

  Future<void> actualizar(Marca marca) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.actualizar(marca);
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
