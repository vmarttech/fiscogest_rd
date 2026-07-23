import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/repositories/entrada_repository_impl.dart';
import '../../domain/entities/entrada.dart';
import '../../domain/interfaces/i_entrada_repository.dart';
import 'producto_providers.dart' hide databaseProvider;

final entradaRepositoryProvider = Provider<IEntradaRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return EntradaRepositoryImpl(db);
});

final historialEntradasProvider = FutureProvider<List<Entrada>>((ref) async {
  final repository = ref.watch(entradaRepositoryProvider);
  return await repository.obtenerHistorialEntradas();
});

class EntradaController extends StateNotifier<AsyncValue<void>> {
  final IEntradaRepository _repository;
  final Ref _ref;

  EntradaController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> registrarEntrada({
    required int productoId,
    required double cantidad,
    required String motivo,
    required String usuario,
  }) async {
    state = const AsyncValue.loading();
    try {
      final entrada = Entrada(
        productoId: productoId,
        cantidad: cantidad,
        motivo: motivo,
        usuario: usuario,
        fecha: DateTime.now(),
      );

      await _repository.registrarEntrada(entrada);
      
      _ref.invalidate(historialEntradasProvider);
      _ref.invalidate(productoControllerProvider);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final entradaControllerProvider = StateNotifierProvider<EntradaController, AsyncValue<void>>((ref) {
  final repository = ref.watch(entradaRepositoryProvider);
  return EntradaController(repository, ref);
});
