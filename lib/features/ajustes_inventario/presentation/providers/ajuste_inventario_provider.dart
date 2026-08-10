import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/ajuste_inventario.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/usecases/registrar_ajuste_usecase.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/usecases/listar_ajustes_usecase.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/inventario_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';

// ✅ NOMBRE PROVEEDOR: TODO MINÚSCULAS (cumpliendo regla)
final ajusteinventarioprovider = AsyncNotifierProvider<AjusteInventarioNotifier, void>(AjusteInventarioNotifier.new);

class AjusteInventarioNotifier extends AsyncNotifier<void> {
  late final RegistrarAjusteUsecase _registrarCasoUso;
  late final ListarAjustesUsecase _listarCasoUso;

  @override
  Future<void> build() async {
    _registrarCasoUso = ref.read(registrarajusteusecaseprovider);
    _listarCasoUso = ref.read(listarajustesusecaseprovider);
  }

  // ✅ MÉTODO registrar DECLARADO EXPLÍCITAMENTE, FIRMA CORRECTA, RETORNO bool
  Future<bool> registrar(AjusteInventario ajuste) async {
    state = const AsyncValue.loading();
    try {
      await _registrarCasoUso.call(ajuste);
      ref.invalidate(ajusteinventariolistaprovider);
      ref.invalidate(productoControllerProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<List<AjusteInventario>> listar() async {
    return _listarCasoUso.call();
  }
}

// ✅ LISTA: MINÚSCULAS
final ajusteinventariolistaprovider = FutureProvider<List<AjusteInventario>>((ref) async {
  return ref.read(ajusteinventarioprovider.notifier).listar();
});

// ✅ CASOS DE USO: proveedores minúsculas
final registrarajusteusecaseprovider = Provider<RegistrarAjusteUsecase>((ref) {
  final repositorio = ref.read(ajusteinventariorepositoryprovider);
  return RegistrarAjusteUsecase(repositorio);
});

final listarajustesusecaseprovider = Provider<ListarAjustesUsecase>((ref) {
  final repositorio = ref.read(ajusteinventariorepositoryprovider);
  return ListarAjustesUsecase(repositorio);
});

// ✅ REPOSITORIO: minúsculas + databaseProvider nombre EXACTO confirmado
final ajusteinventariorepositoryprovider = Provider<AjusteInventarioRepositoryImpl>((ref) {
  final AppDatabase appdb = ref.read(databaseProvider);
  final InventarioRepositoryImpl inventariorepo = InventarioRepositoryImpl(appdb);
  return AjusteInventarioRepositoryImpl(inventariorepo, appdb);
});
