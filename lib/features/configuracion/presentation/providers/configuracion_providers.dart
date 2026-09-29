import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/configuracion/data/dao/configuracion_dao.dart';
import 'package:fiscogest_rd/features/configuracion/data/repositories/configuracion_repository_impl.dart';
import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';
import 'package:fiscogest_rd/features/configuracion/domain/interfaces/i_configuracion_repository.dart';
import 'package:fiscogest_rd/features/configuracion/domain/usecases/guardar_configuracion_usecase.dart';
import 'package:fiscogest_rd/features/configuracion/domain/usecases/obtener_configuracion_usecase.dart';

/// Proveedor DAO Configuración: obtiene BD SOLO del núcleo central
final configuracionDaoProvider = Provider<ConfiguracionDao>((ref) {
  // ✅ Single Source of Truth: única instancia global
  final db = ref.read(databaseProvider);
  return ConfiguracionDao(db);
});

/// Proveedor Repositorio Configuración
final configuracionRepositoryProvider = Provider<IConfiguracionRepository>((
  ref,
) {
  final dao = ref.watch(configuracionDaoProvider);
  return ConfiguracionRepositoryImpl(dao);
});

/// Proveedor Caso de Uso: Obtener Configuración
final obtenerConfiguracionUseCaseProvider =
    Provider<ObtenerConfiguracionUseCase>((ref) {
      final repo = ref.watch(configuracionRepositoryProvider);
      return ObtenerConfiguracionUseCase(repo);
    });

/// Proveedor Caso de Uso: Guardar Configuración
final guardarConfiguracionUseCaseProvider =
    Provider<GuardarConfiguracionUseCase>((ref) {
      final repo = ref.watch(configuracionRepositoryProvider);
      return GuardarConfiguracionUseCase(repo);
    });

/// Controlador Configuración: SOLO gestiona estado, NUNCA lógica de negocio
final configuracionControllerProvider =
    AsyncNotifierProvider<ConfiguracionController, ConfiguracionEntity?>(() {
      return ConfiguracionController();
    });

class ConfiguracionController extends AsyncNotifier<ConfiguracionEntity?> {
  @override
  Future<ConfiguracionEntity?> build() async {
    ref.keepAlive();
    final obtener = ref.read(obtenerConfiguracionUseCaseProvider);
    return await obtener.ejecutar();
  }

  Future<void> guardar(ConfiguracionEntity configuracion) async {
    final previous = state;
    state = const AsyncValue<ConfiguracionEntity?>.loading()
        .copyWithPrevious(previous);
    state = await AsyncValue.guard(() async {
      final guardarUseCase = ref.read(guardarConfiguracionUseCaseProvider);
      await guardarUseCase.ejecutar(configuracion);
      return await ref.read(obtenerConfiguracionUseCaseProvider).ejecutar();
    });
    final cfg = state.valueOrNull;
    if (cfg != null) {
      ref.read(modoSimplificadoCacheProvider.notifier).state =
          cfg.modoSimplificado;
    }
  }
}

/// Último valor conocido (no vuelve a false en loading).
final modoSimplificadoCacheProvider = StateProvider<bool>((ref) => false);

/// Lectura estable para dashboard / menú / ventas.
final modoSimplificadoProvider = Provider<bool>((ref) {
  final live = ref.watch(configuracionControllerProvider).valueOrNull;
  if (live != null) {
    final v = live.modoSimplificado;
    if (ref.read(modoSimplificadoCacheProvider) != v) {
      Future.microtask(() {
        ref.read(modoSimplificadoCacheProvider.notifier).state = v;
      });
    }
    return v;
  }
  return ref.watch(modoSimplificadoCacheProvider);
});
