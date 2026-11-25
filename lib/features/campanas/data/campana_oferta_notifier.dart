// [CAMPANAS_FASE1] Avisa a los negocios elegibles cuando una campaña nace o
// se reactiva. Reusa AvisosRemote (RPC admin_enviar_aviso, tipo 'oferta') para
// que la campana del top bar y el listado de avisos muestren la novedad.
import 'package:fiscogest_rd/features/campanas/domain/campana_promocional.dart';
import 'package:fiscogest_rd/features/notificaciones/data/avisos_remote.dart';

class CampanaOfertaNotifier {
  CampanaOfertaNotifier._();

  static final AvisosRemote _api = AvisosRemote();

  /// Las 'nuevas_cuentas' aun no existen como negocio al crearse la campana;
  /// su descubrimiento es el selector del alta (setup_cuenta_page).
  static bool _debeAvisar(String segmento) => segmento != 'nuevas_cuentas';

  static Future<void> anunciarCreacion({
    required String nombre,
    required String descripcion,
    required String tipo,
    required String valor,
    required String segmento,
    String? planAplicar,
  }) async {
    if (!_debeAvisar(segmento)) return;
    final esPlan = segmento == 'plan_especifico';
    final cuerpo = descripcion.trim().isNotEmpty
        ? descripcion.trim()
        : 'Nueva oferta disponible (${_tipoTxt(tipo)}: $valor). '
            'Entra en "Ofertas disponibles" para aprovecharla.';
    await _enviar(
      titulo: 'Nueva oferta: $nombre',
      mensaje: cuerpo,
      segmento: esPlan ? 'plan' : 'todos',
      plan: esPlan ? planAplicar : null,
    );
  }

  static Future<void> anunciarActivacion(CampanaPromocional c) async {
    if (!c.activa || !_debeAvisar(c.segmentoObjetivo)) return;
    final esPlan = c.segmentoObjetivo == 'plan_especifico';
    final cuerpo = c.descripcion.isNotEmpty
        ? c.descripcion
        : 'Ya disponible (${c.tipoEtiqueta}: ${c.valor}). '
            'Entra en "Ofertas disponibles" para aprovecharla.';
    await _enviar(
      titulo: 'Oferta activa: ${c.nombre}',
      mensaje: cuerpo,
      segmento: esPlan ? 'plan' : 'todos',
      plan: esPlan ? c.planAplicar : null,
    );
  }

  static Future<void> _enviar({
    required String titulo,
    required String mensaje,
    required String segmento,
    String? plan,
  }) async {
    try {
      await _api.enviar(
        tipo: 'oferta',
        titulo: titulo,
        mensaje: mensaje,
        segmento: segmento,
        plan: plan,
        prioridad: 'normal',
      );
    } catch (_) {
      // El aviso nunca debe bloquear crear/activar la campana.
    }
  }

  static String _tipoTxt(String t) => switch (t) {
        'descuento' => 'descuento',
        'meses_gratis' => 'meses gratis',
        'cuentas_gratis' => 'cuentas gratis',
        _ => 'beneficio',
      };
}
