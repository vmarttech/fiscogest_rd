
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';

class UsuarioSesion {
  const UsuarioSesion({
    required this.id,
    required this.username,
    required this.nombre,
    required this.rol,
    required this.requiereSetupInicial,
  });

  final int id;
  final String username;
  final String nombre;
  final String rol;
  final bool requiereSetupInicial;

  bool get esAdmin {
    final r = rol.toLowerCase();
    return r == 'admin' || r == 'administrador';
  }
}

final sesionProvider = StateProvider<UsuarioSesion?>((ref) => null);

final sesionUsuarioIdProvider = Provider<int?>((ref) {
  return ref.watch(sesionProvider)?.id;
});

final sesionUsernameProvider = Provider<String?>((ref) {
  return ref.watch(sesionProvider)?.username;
});

/// Colmado (Fiao / Contado-Fiao / hub informal): solo Admin + modo simplificado.
final modoColmadoProvider = Provider<bool>((ref) {
  final modo = ref.watch(modoSimplificadoProvider);
  final sesion = ref.watch(sesionProvider);
  return modo && (sesion?.esAdmin ?? false);
});
