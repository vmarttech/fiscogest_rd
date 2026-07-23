import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/configuracion/data/dao/configuracion_dao.dart';
import 'package:fiscogest_rd/features/configuracion/data/repositories/configuracion_repository_impl.dart';
import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';
import 'package:fiscogest_rd/features/configuracion/domain/interfaces/i_configuracion_repository.dart';
import 'package:fiscogest_rd/features/configuracion/domain/usecases/guardar_configuracion_usecase.dart';
import 'package:fiscogest_rd/features/configuracion/domain/usecases/obtener_configuracion_usecase.dart';

final configuracionDaoProvider = Provider<ConfiguracionDao>((ref) {
  final db = ref.watch(databaseProvider);
  return ConfiguracionDao(db);
});

final configuracionRepositoryProvider = Provider<IConfiguracionRepository>((ref) {
  final dao = ref.watch(configuracionDaoProvider);
  return ConfiguracionRepositoryImpl(dao);
});

final obtenerConfiguracionUseCaseProvider = Provider<ObtenerConfiguracionUseCase>((ref) {
  final repo = ref.watch(configuracionRepositoryProvider);
  return ObtenerConfiguracionUseCase(repo);
});

final guardarConfiguracionUseCaseProvider = Provider<GuardarConfiguracionUseCase>((ref) {
  final repo = ref.watch(configuracionRepositoryProvider);
  return GuardarConfiguracionUseCase(repo);
});

final configuracionControllerProvider = AsyncNotifierProvider<ConfiguracionController, ConfiguracionEntity?>(() {
  return ConfiguracionController();
});

class ConfiguracionController extends AsyncNotifier<ConfiguracionEntity?> {
  @override
  Future<ConfiguracionEntity?> build() async {
    final obtener = ref.read(obtenerConfiguracionUseCaseProvider);
    return await obtener.ejecutar();
  }

  Future<void> guardar(ConfiguracionEntity configuracion) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final guardarUseCase = ref.read(guardarConfiguracionUseCaseProvider);
      await guardarUseCase.ejecutar(configuracion);
      final obtener = ref.read(obtenerConfiguracionUseCaseProvider);
      return await obtener.ejecutar();
    });
  }
}