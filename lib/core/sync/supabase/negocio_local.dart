import 'package:shared_preferences/shared_preferences.dart';

/// Identidad del negocio en este dispositivo.
///
/// Reglas:
/// - getId() devuelve null si aún no hay negocio vinculado (no inventa id).
/// - idPrueba solo para desarrollo explícito (ensureIdPruebaDev).
/// - Tras registro o login, siempre setId(uuid real de public.negocios).
class NegocioLocal {
  static const _kId = 'supabase_negocio_id';

  /// Solo desarrollo / datos de prueba MartTech. NO usar como default.
  static const idPrueba = 'b44bb611-f50c-44c5-ac80-48c27c5759b1';

  /// null = este dispositivo aún no pertenece a un negocio en la nube.
  static Future<String?> getId() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_kId)?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  static Future<void> setId(String id) async {
    final t = id.trim();
    if (t.isEmpty) {
      throw ArgumentError('negocio_id vacío');
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(_kId, t);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kId);
  }

  static Future<bool> get tieneNegocio async {
    final id = await getId();
    return id != null && id.isNotEmpty;
  }

  /// Únicamente para builds de desarrollo cuando quieras forzar el negocio de prueba.
  static Future<void> ensureIdPruebaDev() async {
    final cur = await getId();
    if (cur == null || cur.isEmpty) {
      await setId(idPrueba);
    }
  }
}
