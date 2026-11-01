import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT de Edge Function. Fallo de red ≠ cerrar la app.
class SupabaseSession {
  static const _kToken = 'supabase_access_token';
  static const _kExp = 'supabase_access_exp';

  static const _secure = FlutterSecureStorage();

  static Future<void> save({
    required String token,
    required int expiresIn,
  }) async {
    final exp =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresIn - 60;
    await _secure.write(key: _kToken, value: token);
    await _secure.write(key: _kExp, value: '$exp');
  }

  static Future<void> clear() async {
    await _secure.delete(key: _kToken);
    await _secure.delete(key: _kExp);
  }

  static Future<String?> accessToken() async {
    final t = await _secure.read(key: _kToken);
    if (t == null || t.isEmpty) return null;
    final exp = int.tryParse(await _secure.read(key: _kExp) ?? '') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (exp > 0 && now >= exp) {
      await clear();
      return null;
    }
    return t;
  }
}
