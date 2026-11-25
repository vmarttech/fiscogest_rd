// [CAMPANAS_FASE1] Providers de campañas.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/campanas/data/campanas_remote.dart';
import 'package:fiscogest_rd/features/campanas/domain/campana_promocional.dart';

final campanasRemoteProvider =
    Provider<CampanasRemote>((ref) => CampanasRemote());

final campanasTickProvider = StateProvider<int>((ref) => 0);

/// Panel del dueño: listado completo.
final campanasAdminProvider =
    FutureProvider.autoDispose<List<CampanaPromocional>>((ref) async {
  ref.watch(campanasTickProvider);
  return ref.read(campanasRemoteProvider).adminListar();
});

/// Negocios: solo vigentes para el panel de ofertas.
final campanasVigentesProvider =
    FutureProvider.autoDispose<List<CampanaPromocional>>((ref) async {
  ref.watch(campanasTickProvider);
  return ref.read(campanasRemoteProvider).vigentes();
});


/// Campañas que el negocio actual ya aprovechó.
final misCampanasAplicadasProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  ref.watch(campanasTickProvider);
  return ref.read(campanasRemoteProvider).misUsos();
});
