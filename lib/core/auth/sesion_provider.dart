import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:fiscogest_rd/core/auth/permisos_roles.dart';

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

  String get rolNorm => normalizarRol(rol);

  bool get esAdmin => rolNorm == 'Admin';

  bool puede(String permiso) => rolTienePermiso(rol, permiso);

  String get rutaInicio => rutaInicioParaRol(rol);
}

final sesionProvider = StateProvider<UsuarioSesion?>((ref) => null);

final sesionUsuarioIdProvider = Provider<int?>((ref) {
  return ref.watch(sesionProvider)?.id;
});

final sesionUsernameProvider = Provider<String?>((ref) {
  return ref.watch(sesionProvider)?.username;
});

/// ¿El usuario actual tiene [permiso]?
final puedeProvider = Provider.family<bool, String>((ref, permiso) {
  final s = ref.watch(sesionProvider);
  if (s == null) return false;
  return s.puede(permiso);
});

/// Colmado solo si config simplificada Y permiso fiao (Admin lo tiene vía *).
final modoColmadoProvider = Provider<bool>((ref) {
  final modo = ref.watch(modoSimplificadoProvider);
  final s = ref.watch(sesionProvider);
  if (!modo || s == null) return false;
  return s.puede(Permiso.fiaoUsar);
});
