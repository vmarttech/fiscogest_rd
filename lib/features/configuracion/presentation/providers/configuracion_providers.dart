import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';
import 'package:fiscogest_rd/features/configuracion/domain/usecases/obtener_configuracion_usecase.dart';
import 'package:fiscogest_rd/features/configuracion/domain/usecases/guardar_configuracion_usecase.dart';
import 'package:fiscogest_rd/features/configuracion/data/repositories/configuracion_repository_impl.dart';
import 'package:fiscogest_rd/features/configuracion/domain/interfaces/i_configuracion_repository.dart';

// ✅ CORREGIDO: nombre + tipo explícito, elimina no definido/tipo dinámico
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final configuracionRepositoryProvider = Provider<IConfiguracionRepository>((ref) {
  // ✅ TIPO EXPLÍCITO: resuelve inferencia fallida y asignación dinámica
  final AppDatabase db = ref.watch(appDatabaseProvider);
  return ConfiguracionRepositoryImpl(db);
});

final obtenerConfiguracionUseCaseProvider = Provider<ObtenerConfiguracionUseCase>((ref) {
  final repo = ref.watch(configuracionRepositoryProvider);
  return ObtenerConfiguracionUseCase(repo);
});

final guardarConfiguracionUseCaseProvider = Provider<GuardarConfiguracionUseCase>((ref) {
  final repo = ref.watch(configuracionRepositoryProvider);
  return GuardarConfiguracionUseCase(repo);
});

final configuracionActualProvider = FutureProvider<ConfiguracionEmpresa?>((ref) async {
  final casoUso = ref.watch(obtenerConfiguracionUseCaseProvider);
  return casoUso.call();
});
