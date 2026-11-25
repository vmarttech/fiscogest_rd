// [CAMPANAS_FASE1] Aplica la campaña elegida durante el alta cuando ya hay JWT.
import 'package:fiscogest_rd/features/campanas/data/campanas_remote.dart';
import 'package:fiscogest_rd/features/campanas/data/campana_pendiente_store.dart';

class CampanaPendienteAplicador {
  /// Lee el pendiente local y lo aplica con la RPC (requiere sesión/JWT).
  /// Si falla, conserva el id para reintentar en el próximo inicio con token.
  static Future<bool> intentarAplicar() async {
    final id = await CampanaPendienteStore.leer();
    if (id == null) return false;
    try {
      final ok = await CampanasRemote().aplicar(id);
      if (ok['aplicado'] == true) {
        await CampanaPendienteStore.limpiar();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
