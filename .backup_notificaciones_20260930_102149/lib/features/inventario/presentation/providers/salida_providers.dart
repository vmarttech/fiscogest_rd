import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/servicios_transversales/operaciones_salida_service.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_salida_repository.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/salida_repository_impl.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart' as repo;
import 'package:fiscogest_rd/features/inventario/domain/entities/salida.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';

final salidaRepositoryProvider = Provider<ISalidaRepository>((Ref ref) {
  return SalidaRepositoryImpl(ref.watch(databaseProvider));
});

final operacionesSalidaServiceProvider = Provider<OperacionesSalidaService>((Ref ref) {
  return OperacionesSalidaService(
    salidaRepository: ref.watch(salidaRepositoryProvider),
    productoRepository: ref.watch(repo.inventarioProductoRepositoryProvider),
    db: ref.watch(databaseProvider),
  );
});

final historialSalidasProvider = FutureProvider<List<Salida>>((Ref ref) async {
  return ref.watch(salidaRepositoryProvider).obtenerHistorialSalidas();
});

class SalidaController extends StateNotifier<AsyncValue<void>> {
  SalidaController(this._servicio, this._ref) : super(const AsyncValue.data(null));

  final OperacionesSalidaService _servicio;
  final Ref _ref;

  Future<void> registrarSalida({
    required int productoId,
    required double cantidad,
    required String motivo,
    required String usuario,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _servicio.registrarSalidaConValidacionStock(
        productoId: productoId,
        cantidad: cantidad,
        motivo: motivo,
        usuario: usuario,
      );
      _ref.invalidate(historialSalidasProvider);
      _ref.invalidate(productoControllerProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final salidaControllerProvider = StateNotifierProvider<SalidaController, AsyncValue<void>>((Ref ref) {
  return SalidaController(ref.watch(operacionesSalidaServiceProvider), ref);
});
