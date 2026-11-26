import 'package:fiscogest_rd/features/licencias/domain/dispositivo_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_service.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_estado.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_limites_guard.dart';
import 'package:fiscogest_rd/core/sync/supabase/licencia_sync.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/features/licencias/domain/device_fingerprint.dart';
import 'package:fiscogest_rd/features/licencias/domain/validacion_dispositivo.dart';
import 'package:fiscogest_rd/features/licencias/domain/validador_dispositivo_remoto_supabase.dart';

final licenciaServiceProvider = Provider<LicenciaService>((ref) {
  final db = ref.watch(databaseProvider);
  return LicenciaService(db);
});

final licenciaActualProvider = FutureProvider<LicenciaInfo?>((ref) async {
  final svc = ref.watch(licenciaServiceProvider);
  await svc.ensureLicenciaInicial();
  await svc.expirarPedidosVencidos();

  // F8: refresca el contrato desde la nube y valida el equipo. El servidor es
  // la única fuente de verdad para prueba/gracia; sin sesión o sin red no
  // bloquea la app (cae al estado local offline).
  try {
    if (SupabaseConfig.isConfigured) {
      final db = ref.read(databaseProvider);
      await LicenciaSync(db).pullDesdeNegocio();
      final identity = await DeviceFingerprint.obtenerResultado();
      await ValidadorDispositivoRemotoSupabase().validar(
        SolicitudValidacionDispositivo(identidad: identity),
      );
    }
  } catch (_) {}

  return svc.obtenerActual();
});

final licenciaUsoGratisProvider = StreamProvider.autoDispose<Map<String, int>>((
  ref,
) async* {
  final guard = LicenciaLimitesGuard(ref.watch(databaseProvider));
  yield await guard.resumenUsoGratis();
  await for (final _ in LicenciaUsoSignals.cambios) {
    yield await guard.resumenUsoGratis();
  }
});

final dispositivoServiceProvider = Provider<DispositivoService>((ref) {
  return DispositivoService(ref.watch(databaseProvider));
});

final dispositivosListaProvider =
    FutureProvider.autoDispose<List<DispositivoInfo>>((ref) async {
      final svc = ref.watch(dispositivoServiceProvider);
      await svc.ensureDispositivoRegistrado();
      return svc.listar();
    });
