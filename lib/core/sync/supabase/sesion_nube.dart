import 'package:shared_preferences/shared_preferences.dart';

/// JWT de la nube. Si no hay token vigente, el REST usa la anon key.
class SesionNube {
  static const _kToken = 'supabase_access_jwt_v2';
  static const _kExp = 'supabase_access_exp_v2';
  static const _kRefresh = 'supabase_refresh_jwt_v2';

  static Future<void> guardar({
    required String token,
    required int expiresInSec,
    String? refreshToken,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, token);
    final exp = DateTime.now()
        .add(Duration(seconds: expiresInSec))
        .millisecondsSinceEpoch;
    await p.setInt(_kExp, exp);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await p.setString(_kRefresh, refreshToken);
    }
  }

  /// Segundos hasta que vence el access token. null si no hay.
  static Future<int?> segundosRestantes() async {
    final p = await SharedPreferences.getInstance();
    final exp = p.getInt(_kExp);
    if (exp == null) return null;
    return ((exp - DateTime.now().millisecondsSinceEpoch) / 1000).floor();
  }

  static Future<String?> refreshToken() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString(_kRefresh);
    if (t == null || t.isEmpty) return null;
    return t;
  }

  /// Token vigente o null (caduca 60 s antes).
  static Future<String?> tokenVigente() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString(_kToken);
    if (t == null || t.isEmpty) return null;
    final exp = p.getInt(_kExp) ?? 0;
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
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kExp);
    await p.remove(_kRefresh);
  }
}
