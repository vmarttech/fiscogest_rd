import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT de la nube. Si no hay token vigente, el REST usa la anon key.
/// No bloquea el uso offline de la app: solo afecta sync/API remota.
class SesionNube {
  static const _kToken = 'supabase_access_jwt_v2';
  static const _kExp = 'supabase_access_exp_v2';
  static const _kRefresh = 'supabase_refresh_jwt_v2';

  static const _secure = FlutterSecureStorage();

  static Future<void> guardar({
    required String token,
    required int expiresInSec,
    String? refreshToken,
  }) async {
    await _secure.write(key: _kToken, value: token);
    final exp = DateTime.now()
        .add(Duration(seconds: expiresInSec))
        .millisecondsSinceEpoch;
    await _secure.write(key: _kExp, value: '$exp');
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secure.write(key: _kRefresh, value: refreshToken);
    }
  }

  static Future<int?> segundosRestantes() async {
    final expStr = await _secure.read(key: _kExp);
    if (expStr == null || expStr.isEmpty) return null;
    final exp = int.tryParse(expStr);
    if (exp == null) return null;
    return ((exp - DateTime.now().millisecondsSinceEpoch) / 1000).floor();
  }

  static Future<String?> refreshToken() async {
    final t = await _secure.read(key: _kRefresh);
    if (t == null || t.isEmpty) return null;
    return t;
  }

  /// Token vigente o null (caduca 60 s antes).
  static Future<String?> tokenVigente() async {
    final t = await _secure.read(key: _kToken);
    if (t == null || t.isEmpty) return null;
    final expStr = await _secure.read(key: _kExp);
    final exp = int.tryParse(expStr ?? '') ?? 0;
    final limite = DateTime.now()
        .add(const Duration(seconds: 60))
        .millisecondsSinceEpoch;
    if (exp <= limite) return null;
    return t;
  }

  static Future<DateTime?> expiraEn() async {
    final s = await segundosRestantes();
    if (s == null) return null;
    return DateTime.now().add(Duration(seconds: s));
  }

  static Future<String?> leerRefresh() => refreshToken();

  static Future<void> clear() async {
    await _secure.delete(key: _kToken);
    await _secure.delete(key: _kExp);
    await _secure.delete(key: _kRefresh);
  }
}
