import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de login: recordar usuario + opción biometría.
class LoginPrefs {
  static const _kUser = 'login_remember_user';
  static const _kRemember = 'login_remember_me';
  static const _kBio = 'login_biometric_enabled';

  static const _secUser = 'bio_username';
  static const _secPass = 'bio_password';

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<String?> getRememberedUser() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(_kRemember) != true) return null;
    return p.getString(_kUser);
  }

  static Future<bool> getRememberMe() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kRemember) ?? false;
  }

  static Future<void> setRememberMe(bool value, String username) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kRemember, value);
    if (value && username.trim().isNotEmpty) {
      await p.setString(_kUser, username.trim());
    } else if (!value) {
      await p.remove(_kUser);
    }
  }

  static Future<bool> isBiometricEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kBio) ?? false;
  }

  /// Guarda credenciales solo si el usuario activa biometría.
  static Future<void> enableBiometric({
    required String username,
    required String password,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kBio, true);
    await _secure.write(key: _secUser, value: username.trim());
    await _secure.write(key: _secPass, value: password);
  }

  static Future<void> disableBiometric() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kBio, false);
    await _secure.delete(key: _secUser);
    await _secure.delete(key: _secPass);
  }

  static Future<({String user, String pass})?> readBiometricCredentials() async {
    if (!await isBiometricEnabled()) return null;
    final u = await _secure.read(key: _secUser);
    final pass = await _secure.read(key: _secPass);
    if (u == null || pass == null || u.isEmpty || pass.isEmpty) return null;
    return (user: u, pass: pass);
  }
}
