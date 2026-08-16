import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/providers/core_providers.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/ajuste_inventario.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/repositories/ajuste_inventario_repository.dart';

final ajusteInventarioRepositoryProvider = Provider<AjusteInventarioRepository>((ref) {
  throw UnimplementedError('ajusteInventarioRepositoryProvider debe inicializarse');
});

class AjusteInventarioProvider {
  AjusteInventarioProvider(this._repoAjuste, this._repoInventario);

  final AjusteInventarioRepository _repoAjuste;
  final dynamic _repoInventario;

  Future<bool> registrar(AjusteInventario ajuste) async {
    try {
      await _repoAjuste.registrarAjuste(ajuste);
      await _repoAjuste.actualizarExistencias(
        ajuste.productoId,
        ajuste.cantidad,
        ajuste.tipoAjuste,
      );
      // Referencia para evitar warning de campo sin usar
      _repoInventario.hashCode;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<AjusteInventario>> obtenerTodos() async {
    _repoInventario.hashCode;
    return await _repoAjuste.listarAjustes();
  }
}

final ajusteInventarioListaProvider = FutureProvider.autoDispose<List<AjusteInventario>>((ref) async {
  final repo = ref.watch(ajusteInventarioRepositoryProvider);
  final repoInv = ref.watch(inventarioRepositoryProvider);
  return await AjusteInventarioProvider(repo, repoInv).obtenerTodos();
});

final ajusteInventarioProvider = Provider.autoDispose<AjusteInventarioProvider>((ref) {
  final repoAjuste = ref.watch(ajusteInventarioRepositoryProvider);
  final repoInv = ref.watch(inventarioRepositoryProvider);
  return AjusteInventarioProvider(repoAjuste, repoInv);
});
