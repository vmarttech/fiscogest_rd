// [AVISOS_FASE1] Providers de avisos remotos.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/notificaciones/data/avisos_remote.dart';
import 'package:fiscogest_rd/features/notificaciones/domain/aviso_remoto.dart';

final avisosRemoteProvider = Provider<AvisosRemote>((ref) => AvisosRemote());

final avisosRemotosProvider =
    FutureProvider.autoDispose<List<AvisoRemoto>>((ref) async {
  return ref.read(avisosRemoteProvider).listar();
});

final avisosNoLeidosProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.read(avisosRemoteProvider).noLeidos();
});

/// Tras enviar o marcar avisos, refresca lista y contador.
void invalidarAvisos(WidgetRef ref) {
  ref.invalidate(avisosRemotosProvider);
  ref.invalidate(avisosNoLeidosProvider);
}

Future<void> marcarAvisoLeido(WidgetRef ref, String id) async {
  try {
    await ref.read(avisosRemoteProvider).marcarLeido(id);
  } catch (_) {
    // Sin red/token: la campana local sigue funcionando.
  }
  invalidarAvisos(ref);
}

Future<void> marcarAvisosTodosLeidos(WidgetRef ref) async {
  try {
    await ref.read(avisosRemoteProvider).marcarTodosLeidos();
  } catch (_) {}
  invalidarAvisos(ref);
}
