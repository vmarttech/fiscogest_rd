import 'package:riverpod/riverpod.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/recepcion.dart';
import 'package:fiscogest_rd/features/comercial/domain/services/recepcion_service.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/recepcion_repository_impl.dart';

final recepcionServiceProvider = Provider<RecepcionService>((ref) {
  final repo = RecepcionRepositoryImpl();
  return RecepcionService(repo);
});

class RecepcionNotifier extends StateNotifier<AsyncValue<List<Recepcion>>> {
  RecepcionNotifier(this._service) : super(const AsyncValue.data([]));
  final RecepcionService _service;
  final Map<String, Recepcion> _repoCache = {};

  Future<void> registrar(Recepcion recepcion, String usuarioResponsable) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.registrar(recepcion, usuarioResponsable);
      if (recepcion.id != null) {
        _repoCache[recepcion.id!] = recepcion;
      }
      return _repoCache.values.toList();
    });
  }

  Future<void> listarTodos({DateTime? desde, DateTime? hasta}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = RecepcionRepositoryImpl();
      final lista = await repo.listarTodos(desde: desde, hasta: hasta);
      _repoCache.clear();
      for (var r in lista) {
        if (r.id != null) _repoCache[r.id!] = r;
      }
      return lista;
    });
  }
}

final recepcionNotifierProvider =
    StateNotifierProvider<RecepcionNotifier, AsyncValue<List<Recepcion>>>((ref) {
  final service = ref.watch(recepcionServiceProvider);
  return RecepcionNotifier(service);
});
