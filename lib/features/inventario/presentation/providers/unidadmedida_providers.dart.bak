import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/inventario/data/dao/unidadmedida_dao.dart';
import 'package:fiscogest_rd/features/inventario/data/repositories/unidadmedida_repository_impl.dart';
import 'package:fiscogest_rd/features/inventario/domain/interfaces/i_unidadmedida_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/usecases/obtener_todos_unidadmedida_usecase.dart';
import 'package:fiscogest_rd/features/inventario/domain/usecases/guardar_unidadmedida_usecase.dart';
import 'package:fiscogest_rd/features/inventario/domain/usecases/actualizar_unidadmedida_usecase.dart';
import 'package:fiscogest_rd/features/inventario/domain/usecases/eliminar_unidadmedida_usecase.dart';

final unidadMedidaDaoProvider = Provider<UnidadMedidaDao>((ref) {
  final db = ref.watch(databaseProvider);
  return UnidadMedidaDao(db);
});

final unidadMedidaRepositoryProvider = Provider<IUnidadMedidaRepository>((ref) {
  final dao = ref.watch(unidadMedidaDaoProvider);
  return UnidadMedidaRepositoryImpl(dao);
});

final obtenerTodosUnidadMedidaUseCaseProvider = Provider<ObtenerTodosUnidadMedidaUseCase>((ref) {
  final repo = ref.watch(unidadMedidaRepositoryProvider);
  return ObtenerTodosUnidadMedidaUseCase(repo);
});

final guardarUnidadMedidaUseCaseProvider = Provider<GuardarUnidadMedidaUseCase>((ref) {
  final repo = ref.watch(unidadMedidaRepositoryProvider);
  return GuardarUnidadMedidaUseCase(repo);
});

final actualizarUnidadMedidaUseCaseProvider = Provider<ActualizarUnidadMedidaUseCase>((ref) {
  final repo = ref.watch(unidadMedidaRepositoryProvider);
  return ActualizarUnidadMedidaUseCase(repo);
});

final eliminarUnidadMedidaUseCaseProvider = Provider<EliminarUnidadMedidaUseCase>((ref) {
  final repo = ref.watch(unidadMedidaRepositoryProvider);
  return EliminarUnidadMedidaUseCase(repo);
});