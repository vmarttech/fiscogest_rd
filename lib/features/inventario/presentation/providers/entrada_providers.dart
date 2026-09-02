import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/servicios_transversales/operaciones_entrada_service.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/entrada_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/entrada.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_entrada_repository.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';

final entradaRepositoryProvider = Provider<IEntradaRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return EntradaRepositoryImpl(db);
});

final operacionesEntradaServiceProvider = Provider<OperacionesEntradaService>((
  ref,
) {
  return OperacionesEntradaService(
    entradaRepository: ref.watch(entradaRepositoryProvider),
    productoRepository: ref.watch(productoRepositoryProvider),
    db: ref.watch(databaseProvider),
  );
});

final historialEntradasProvider = FutureProvider<List<Entrada>>((ref) async {
  final repository = ref.watch(entradaRepositoryProvider);
  return await repository.obtenerHistorialEntradas();
});

class EntradaController extends StateNotifier<AsyncValue<void>> {
  EntradaController(this._operacionesEntrada, this._ref)
    : super(const AsyncValue.data(null));

  final OperacionesEntradaService _operacionesEntrada;
  final Ref _ref;

  Future<void> registrarEntrada({
    required int productoId,
    required double cantidad,
    required String motivo,
    required String usuario,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _operacionesEntrada.registrarEntradaConAjusteStock(
        productoId: productoId,
        cantidad: cantidad,
        motivo: motivo,
        usuario: usuario,
      );
      _ref.invalidate(historialEntradasProvider);
      _ref.invalidate(productoControllerProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final entradaControllerProvider =
    StateNotifierProvider<EntradaController, AsyncValue<void>>((ref) {
      final servicio = ref.watch(operacionesEntradaServiceProvider);
      return EntradaController(servicio, ref);
    });
