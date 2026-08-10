// 1. Corregimos importaciones: usamos flutter_riverpod (tu ya lo tenías así) y rutas reales
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/ajuste_inventario.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/usecases/registrar_ajuste_usecase.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/usecases/listar_ajustes_usecase.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/inventario_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';

// ✅ Gestor de estado oficial
final ajusteInventarioProvider = AsyncNotifierProvider<AjusteInventarioNotifier, void>(AjusteInventarioNotifier.new);

class AjusteInventarioNotifier extends AsyncNotifier<void> {
  late final RegistrarAjusteUsecase _registrarUsecase;
  late final ListarAjustesUsecase _listarUsecase;

  @override
  Future<void> build() async {
    _registrarUsecase = ref.read(registrarAjusteUsecaseProvider);
    _listarUsecase = ref.read(listarAjustesUsecaseProvider);
  }

  Future<bool> registrar(AjusteInventario ajuste) async {
    state = const AsyncLoading();
    try {
      await _registrarUsecase.call(ajuste);
      ref.invalidate(ajusteInventarioListaProvider);
      ref.invalidate(productoControllerProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<List<AjusteInventario>> listar() async {
    return _listarUsecase.call();
  }
}

// ✅ Lista de ajustes
final ajusteInventarioListaProvider = FutureProvider<List<AjusteInventario>>((ref) async {
  return ref.read(ajusteInventarioProvider.notifier).listar();
});

// ✅ Proveedores de Casos de Uso
final registrarAjusteUsecaseProvider = Provider<RegistrarAjusteUsecase>((ref) {
  final repo = ref.read(AjusteInventarioRepositoryImplProvider);
  return RegistrarAjusteUsecase(repo);
});

final listarAjustesUsecaseProvider = Provider<ListarAjustesUsecase>((ref) {
  final repo = ref.read(AjusteInventarioRepositoryImplProvider);
  return ListarAjustesUsecase(repo);
});

// ✅ Repositorio con tus rutas reales
final AjusteInventarioRepositoryImplProvider = Provider<AjusteInventarioRepositoryImplImpl>((ref) {
  final AppDatabase appDb = ref.read(databaseProvider);
  final inventarioRepo = InventarioRepositoryImpl(appDb);
  return AjusteInventarioRepositoryImplImpl(inventarioRepo, appDb);
});
