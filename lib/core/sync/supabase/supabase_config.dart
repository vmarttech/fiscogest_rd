import 'package:http/http.dart' as http;
import 'package:fiscogest_rd/core/sync/supabase/supabase_secrets.dart';

class SupabaseConfig {
  static const _urlEnv =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const _keyEnv =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static String get url =>
      _urlEnv.isNotEmpty ? _urlEnv : SupabaseSecrets.url;

  static String get anonKey =>
      _keyEnv.isNotEmpty ? _keyEnv : SupabaseSecrets.anonKey;

  static bool get isConfigured =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      url.startsWith('https://') &&
      !anonKey.contains('PEGA_AQUI');

  /// true si Supabase responde (aunque sea 401/404).
  /// Timeout 6s: redes lentas / DNS no deben contar como "sin red".
  static Future<bool> hayRed() async {
    if (!isConfigured) return false;
    try {
      final uri = Uri.parse('$url/rest/v1/');
      await http
          .get(
            uri,
            headers: {
              'apikey': anonKey,
              'Authorization': 'Bearer $anonKey',
            },
          )
          .timeout(const Duration(seconds: 6));
      return true;
    } catch (_) {
      return false;
    }
  }
}
