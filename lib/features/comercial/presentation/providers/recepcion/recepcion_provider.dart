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

  Future<void> registrar(Recepcion recepcion) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.registrar(recepcion);
      return <Recepcion>[];
    });
  }
}
