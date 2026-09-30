import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/historial_costo.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/consultas/obtener_historial_costos_usecase.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart' as repo;

final obtenerHistorialCostosUseCaseProvider = Provider<ObtenerHistorialCostosUseCase>((ref) {
  return ObtenerHistorialCostosUseCase(ref.watch(repo.compraRepositoryProvider));
});

final historialCostosProvider =
    FutureProvider.autoDispose.family<HistorialCostoResumen, int>((ref, productoId) async {
  final useCase = ref.watch(obtenerHistorialCostosUseCaseProvider);
  return useCase(productoId);
});
