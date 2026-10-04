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
}
