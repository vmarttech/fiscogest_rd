import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/impuesto_entity.dart';
import '../../data/repositories/impuesto_repository_impl.dart';

final impuestoRepositoryProvider = Provider<ImpuestoRepositoryImpl>((ref) {
  return ImpuestoRepositoryImpl();
});

class ImpuestoNotifier extends StateNotifier<AsyncValue<List<ImpuestoEntity>>> {
  final ImpuestoRepositoryImpl _repository;

  ImpuestoNotifier(this._repository) : super(const AsyncValue.loading()) {
    cargarImpuestos();
  }

  Future<void> cargarImpuestos() async {
    try {
      final lista = await _repository.obtenerImpuestos();
      state = AsyncValue.data(lista);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> guardar(ImpuestoEntity impuesto) async {
    try {
      await _repository.guardarImpuesto(impuesto);
      await cargarImpuestos();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> actualizar(ImpuestoEntity impuesto) async {
    try {
      await _repository.actualizarImpuesto(impuesto);
      await cargarImpuestos();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> eliminar(int id) async {
    try {
      await _repository.eliminarImpuesto(id);
      await cargarImpuestos();
    } catch (e) {
      rethrow;
    }
  }
}

final impuestoControllerProvider = StateNotifierProvider<ImpuestoNotifier, AsyncValue<List<ImpuestoEntity>>>((ref) {
  final repo = ref.watch(impuestoRepositoryProvider);
  return ImpuestoNotifier(repo);
});
