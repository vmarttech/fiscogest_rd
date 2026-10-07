import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:fiscogest_rd/features/impuestos/data/repositories/impuesto_repository_impl.dart';
import 'package:fiscogest_rd/features/impuestos/domain/entities/impuesto_entity.dart';

final impuestoRepositoryProvider = Provider<ImpuestoRepositoryImpl>((ref) {
  return ImpuestoRepositoryImpl(ref.watch(databaseProvider));
});

class ImpuestoNotifier extends StateNotifier<AsyncValue<List<ImpuestoEntity>>> {
  ImpuestoNotifier(this._repository) : super(const AsyncValue.loading()) {
    cargarImpuestos();
  }

  final ImpuestoRepositoryImpl _repository;

  Future<void> cargarImpuestos() async {
    try {
      final lista = await _repository.obtenerImpuestos();
      state = AsyncValue.data(lista);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> guardar(ImpuestoEntity impuesto) async {
    await _repository.guardarImpuesto(impuesto);
    await cargarImpuestos();
  }

  Future<void> actualizar(ImpuestoEntity impuesto) async {
    await _repository.actualizarImpuesto(impuesto);
    await cargarImpuestos();
  }

  Future<void> eliminar(int id) async {
    await _repository.eliminarImpuesto(id);
    await cargarImpuestos();
  }
}

final impuestoControllerProvider =
    StateNotifierProvider<ImpuestoNotifier, AsyncValue<List<ImpuestoEntity>>>((
      ref,
    ) {
      return ImpuestoNotifier(ref.watch(impuestoRepositoryProvider));
    });

/// Fracción (0.18 = 18%). 0 en modo simplificado.
final tasaItbisVigenteProvider = Provider<double>((ref) {
  final cfg = ref.watch(configuracionControllerProvider).valueOrNull;
  if (cfg?.modoSimplificado == true) return 0.0;
  final lista = ref.watch(impuestoControllerProvider).valueOrNull;
  if (lista != null) {
    final def = lista.where(
      (i) => i.activo && i.tipo == 'ITBIS' && i.esDefault && !i.esExento,
    );
    if (def.isNotEmpty) return def.first.porcentaje / 100.0;
    final itbis = lista.where(
      (i) => i.activo && i.tipo == 'ITBIS' && !i.esExento,
    );
    if (itbis.isNotEmpty) return itbis.first.porcentaje / 100.0;
  }
  final p = cfg?.impuestoPorcentaje;
  if (p != null && p > 0) return p / 100.0;
  return 0.18;
});
