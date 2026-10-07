import 'package:shared_preferences/shared_preferences.dart';

/// JWT de nubes emitido tras el login local.
/// Si no hay token o caducó, el REST sigue con la anon key.
class SesionNube {
  static const _kToken = 'supabase_access_jwt_v2';
  static const _kExp = 'supabase_access_exp_v2';

  static Future<void> guardar({
    required String token,
    required int expiresInSec,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, token);
    final exp = DateTime.now()
        .add(Duration(seconds: expiresInSec))
        .millisecondsSinceEpoch;
    await p.setInt(_kExp, exp);
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

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kExp);
  }
}
