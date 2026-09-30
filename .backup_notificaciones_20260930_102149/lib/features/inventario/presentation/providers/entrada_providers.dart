import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/servicios_transversales/operaciones_entrada_service.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_entrada_repository.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/entrada_repository_impl.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart' as repo;
import 'package:fiscogest_rd/features/inventario/domain/entities/entrada.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';

final entradaRepositoryProvider = Provider<IEntradaRepository>((Ref ref) {
  return EntradaRepositoryImpl(ref.watch(databaseProvider));
});

final operacionesEntradaServiceProvider = Provider<OperacionesEntradaService>((Ref ref) {
  return OperacionesEntradaService(
    entradaRepository: ref.watch(entradaRepositoryProvider),
    productoRepository: ref.watch(repo.inventarioProductoRepositoryProvider),
    db: ref.watch(databaseProvider),
  );
});

final historialEntradasProvider = FutureProvider<List<Entrada>>((Ref ref) async {
  return ref.watch(entradaRepositoryProvider).obtenerHistorialEntradas();
});

class EntradaController extends StateNotifier<AsyncValue<void>> {
  EntradaController(this._servicio, this._ref) : super(const AsyncValue.data(null));

  final OperacionesEntradaService _servicio;
  final Ref _ref;

  Future<void> registrarEntrada({
    required int productoId,
    required double cantidad,
    required String motivo,
    required String usuario,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _servicio.registrarEntradaConAjusteStock(
        productoId: productoId,
        cantidad: cantidad,
        motivo: motivo,
        usuario: usuario,
      );
      _ref.invalidate(historialEntradasProvider);
      _ref.invalidate(productoControllerProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final entradaControllerProvider = StateNotifierProvider<EntradaController, AsyncValue<void>>((Ref ref) {
  return EntradaController(ref.watch(operacionesEntradaServiceProvider), ref);
});
