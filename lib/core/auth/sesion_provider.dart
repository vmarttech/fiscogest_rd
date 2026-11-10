import 'package:fiscogest_rd/core/sync/supabase/roles_acceso_sync.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/sync/supabase/usuario_sync.dart';
import 'package:fiscogest_rd/core/sync/supabase/sync_pull.dart';
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


/// Revalida que el usuario de la sesión siga Activo (local + nube).
/// Si está inactivo → limpia sesión y devuelve false.
Future<bool> revalidarSesionActiva(WidgetRef ref) async {
  final ses = ref.read(sesionProvider);
  if (ses == null) return false;

  final db = ref.read(databaseProvider);

  // 1) Intentar alinear desde Supabase (usuarios del negocio)
  try {
    await RolesAccesoSync.pullYCachear();
    await SyncPull(db).pullTodoElNegocio();
  } catch (_) {
    // sin red: seguimos con chequeo local + consulta puntual
  }

  // 2) Consulta puntual activo en nube
  final activoNube = await UsuarioSync.verificarActivoEnNube(ses.username);
  if (activoNube == false) {
    ref.read(sesionProvider.notifier).state = null;
    return false;
  }

  // 3) Estado local
  final row = await (db.select(db.usuariosTable)
        ..where((t) => t.id.equals(ses.id)))
      .getSingleOrNull();
  if (row == null || row.estado.toLowerCase() != 'activo') {
    ref.read(sesionProvider.notifier).state = null;
    return false;
  }

  // 4) Actualizar rol en sesión si cambió en nube/local
  if (row.rol != ses.rol) {
    ref.read(sesionProvider.notifier).state = UsuarioSesion(
      id: ses.id,
      username: ses.username,
      nombre: ses.nombre,
      rol: row.rol,
      requiereSetupInicial: ses.requiereSetupInicial,
    );
  }
  return true;
}

