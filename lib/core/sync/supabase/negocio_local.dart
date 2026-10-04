import 'package:shared_preferences/shared_preferences.dart';

class NegocioLocal {
  static const _kId = 'supabase_negocio_id';
  static const idPrueba = 'b44bb611-f50c-44c5-ac80-48c27c5759b1';

  static Future<String?> getId() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kId) ?? idPrueba;
  }

  static Future<void> setId(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kId, id.trim());
  }
}
