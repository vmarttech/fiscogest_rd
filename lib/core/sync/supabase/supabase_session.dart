import 'package:shared_preferences/shared_preferences.dart';

/// JWT emitido por la Edge Function. Si no hay o venció, el REST usa la anon key.
class SupabaseSession {
  static const _kToken = 'supabase_access_token';
  static const _kExp = 'supabase_access_exp'; // epoch seconds

  static Future<void> save({required String token, required int expiresIn}) async {
    final prefs = await SharedPreferences.getInstance();
    final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresIn - 60;
    await prefs.setString(_kToken, token);
    await prefs.setInt(_kExp, exp);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kExp);
  }

  static Future<String?> accessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_kToken);
    if (t == null || t.isEmpty) return null;
    final exp = prefs.getInt(_kExp) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (exp > 0 && now >= exp) {
      await clear();
      return null;
    }
    return t;
  }
}
