import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';

/// Conserva únicamente la identidad de la sesión; nunca almacena contraseñas.
class SesionPersistente {
  SesionPersistente._();

  static const _secure = FlutterSecureStorage();
  static const _idKey = 'active_session_user_id';
  static const _usernameKey = 'active_session_username';
  static const _setupKey = 'active_session_requires_setup';
  static const _lastActivityKey = 'active_session_last_activity_ms';
  static const timeoutInactividad = Duration(hours: 5);
  static const _activityWriteInterval = Duration(seconds: 15);

  static DateTime? _lastActivityAt;
  static DateTime? _lastActivitySavedAt;

  static Future<void> guardar(UsuarioSesion sesion) async {
    if (sesion.id <= 0 || sesion.username.toLowerCase() == 'invitado') {
      await limpiar();
      return;
    }
    final now = DateTime.now();
    await _secure.write(key: _idKey, value: '${sesion.id}');
    await _secure.write(key: _usernameKey, value: sesion.username);
    await _secure.write(
      key: _setupKey,
      value: sesion.requiereSetupInicial ? 'true' : 'false',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastActivityKey, now.millisecondsSinceEpoch);
    _lastActivityAt = now;
    _lastActivitySavedAt = now;
  }

  static Future<UsuarioSesion?> restaurar(AppDatabase db) async {
    final id = int.tryParse(await _secure.read(key: _idKey) ?? '');
    final username = await _secure.read(key: _usernameKey);
    if (id == null || username == null || username.isEmpty) {
      await limpiar();
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedAt = prefs.getInt(_lastActivityKey);
    if (savedAt == null) {
      await limpiar();
      return null;
    }
    final lastActivity = DateTime.fromMillisecondsSinceEpoch(savedAt);
    _lastActivityAt = lastActivity;
    _lastActivitySavedAt = lastActivity;
    if (DateTime.now().difference(lastActivity) >= timeoutInactividad) {
      await limpiar();
      return null;
    }

    final row = await (db.select(
      db.usuariosTable,
    )..where((user) => user.id.equals(id))).getSingleOrNull();
    if (row == null ||
        row.username.toLowerCase() != username.toLowerCase() ||
        row.estado.toLowerCase() != 'activo') {
      await limpiar();
      return null;
    }

    final requiereSetupGuardado = await _secure.read(key: _setupKey) == 'true';
    return UsuarioSesion(
      id: row.id,
      username: row.username,
      nombre: row.nombre,
      rol: row.rol,
      requiereSetupInicial: requiereSetupGuardado || row.requiereSetupInicial,
    );
  }

  static Future<bool> expirada() async {
    var lastActivity = _lastActivityAt;
    if (lastActivity == null) {
      final prefs = await SharedPreferences.getInstance();
      final savedAt = prefs.getInt(_lastActivityKey);
      if (savedAt == null) return true;
      lastActivity = DateTime.fromMillisecondsSinceEpoch(savedAt);
      _lastActivityAt = lastActivity;
      _lastActivitySavedAt = lastActivity;
    }
    return DateTime.now().difference(lastActivity) >= timeoutInactividad;
  }

  static Future<void> registrarActividad() async {
    final now = DateTime.now();
    _lastActivityAt = now;
    if (_lastActivitySavedAt != null &&
        now.difference(_lastActivitySavedAt!) < _activityWriteInterval) {
      return;
    }
    await guardarActividad(now);
  }

  static Future<void> guardarActividadActual() async {
    final lastActivity = _lastActivityAt;
    if (lastActivity != null) await guardarActividad(lastActivity);
  }

  static Future<void> guardarActividad(DateTime activity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastActivityKey, activity.millisecondsSinceEpoch);
    _lastActivitySavedAt = activity;
  }

  static Future<void> limpiar() async {
    await _secure.delete(key: _idKey);
    await _secure.delete(key: _usernameKey);
    await _secure.delete(key: _setupKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastActivityKey);
    _lastActivityAt = null;
    _lastActivitySavedAt = null;
  }
}
