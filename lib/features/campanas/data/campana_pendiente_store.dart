// [CAMPANAS_FASE1] Campaña elegida en el alta de una cuenta nueva.
// El alta usa anonKey (sin auth.uid()); el uso se aplica cuando llega el JWT.
import 'package:shared_preferences/shared_preferences.dart';

class CampanaPendienteStore {
  static const _k = 'campana_pendiente_aplicar_v1';

  static Future<String?> leer() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_k)?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  static Future<void> guardar(String campanaId) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_k, campanaId.trim());
  }

  static Future<void> limpiar() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_k);
  }
}
