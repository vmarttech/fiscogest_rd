import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/presentaciones/data/repositories/presentacion_repository.dart';
import 'package:fiscogest_rd/features/presentaciones/domain/entities/presentacion.dart';

class PresentacionNotifier
    extends StateNotifier<AsyncValue<List<Presentacion>>> {
  PresentacionNotifier(this._repo) : super(const AsyncValue.loading()) {
    cargar();
  }

  final PresentacionRepository _repo;

  Future<void> cargar() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repo.obtenerPresentaciones);
  }

  Future<void> guardar(Presentacion presentacion) async {
    await _repo.agregarPresentacion(presentacion);
    await cargar();
  }

  Future<void> actualizar(Presentacion presentacion) async {
    await _repo.actualizarPresentacion(presentacion);
    await cargar();
  }

  Future<void> eliminar(int id) async {
    await _repo.eliminarPresentacion(id);
    await cargar();
  }
}

final presentacionControllerProvider =
    StateNotifierProvider<PresentacionNotifier, AsyncValue<List<Presentacion>>>(
      (ref) {
        return PresentacionNotifier(
          PresentacionRepository(ref.watch(databaseProvider)),
        );
      },
    );
