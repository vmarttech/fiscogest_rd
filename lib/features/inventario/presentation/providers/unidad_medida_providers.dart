import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/unidad_medida_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/unidad_medida.dart';
import 'package:fiscogest_rd/features/inventario/domain/repositories/unidad_medida_repository.dart';

final unidadMedidaRepositoryProvider = Provider<UnidadMedidaRepository>((ref) {
  return UnidadMedidaRepositoryImpl(ref.watch(databaseProvider));
});

final unidadMedidaControllerProvider = AsyncNotifierProvider<UnidadMedidaController, List<UnidadMedida>>(() {
  return UnidadMedidaController();
});

class UnidadMedidaController extends AsyncNotifier<List<UnidadMedida>> {
  late final UnidadMedidaRepository _repo;

  @override
  Future<List<UnidadMedida>> build() async {
    _repo = ref.read(unidadMedidaRepositoryProvider);
    return _repo.obtenerTodos();
  }

  Future<void> guardar(UnidadMedida unidad) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.guardar(unidad);
      return _repo.obtenerTodos();
    });
  }

  Future<void> actualizar(UnidadMedida unidad) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.actualizar(unidad);
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
