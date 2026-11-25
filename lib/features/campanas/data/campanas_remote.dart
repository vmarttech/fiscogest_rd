// [CAMPANAS_FASE1] Cliente RPC de campañas promocionales.
import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';
import 'package:fiscogest_rd/features/campanas/domain/campana_promocional.dart';

class CampanasRemote {
  CampanasRemote([SupabaseRestClient? api])
    : _api = api ?? SupabaseRestClient();
  final SupabaseRestClient _api;

  List<CampanaPromocional> _lista(dynamic res) =>
      (res is List ? res : const <dynamic>[])
          .whereType<Map<dynamic, dynamic>>()
          .map((m) => CampanaPromocional.fromJson(Map<String, dynamic>.from(m)))
          .toList(growable: false);

  /// Panel del dueño: todas las campañas (vigentes, próximas, vencidas, pausadas).
  Future<List<CampanaPromocional>> adminListar() async =>
      _lista(await _api.rpc('admin_listar_campanas', const {}));

  /// Negocios: solo campañas vigentes que deben mostrarse.
  Future<List<CampanaPromocional>> vigentes({
    bool paraRegistro = false,
  }) async => _lista(
    await _api.rpc('listar_campanas_vigentes', {
      'p_para_registro': paraRegistro,
    }),
  );

  Future<String> crear({
    required String nombre,
    String descripcion = '',
    required String tipo,
    required String valor,
    required String segmento,
    String? planAplicar,
    required DateTime inicio,
    required DateTime fin,
    int? limiteUsos,
    bool mostrarRegistro = true,
    bool mostrarPanel = true,
  }) async {
    final res = await _api.rpc('admin_crear_campana', {
      'p_nombre': nombre,
      'p_descripcion': descripcion,
      'p_tipo': tipo,
      'p_valor': valor,
      'p_segmento_objetivo': segmento,
      'p_plan_aplicar': segmento == 'plan_especifico' ? planAplicar : null,
      'p_fecha_inicio': inicio.toUtc().toIso8601String(),
      'p_fecha_fin': fin.toUtc().toIso8601String(),
      'p_limite_usos_total': limiteUsos,
      'p_mostrar_en_registro': mostrarRegistro,
      'p_mostrar_en_panel': mostrarPanel,
    });
    return '$res';
  }

  Future<void> alternar(String campanaId, bool activa) => _api.rpc(
    'admin_alternar_campana',
    {'p_id': campanaId, 'p_activa': activa},
  );

  static Map<String, dynamic> parseAplicado(dynamic res) {
    if (res is Map) return Map<String, dynamic>.from(res);
    if (res == true) return {'aplicado': true};
    return {'aplicado': false, 'razon': 'RESPUESTA_INVALIDA'};
  }

  Future<Map<String, dynamic>> aplicar(String campanaId) async {
    final res = await _api.rpc('negocio_aplicar_campana', {
      'p_campana_id': campanaId,
    });
    return parseAplicado(res);
  }

  /// IDs de campañas ya aprovechadas por el negocio del usuario.
  Future<Set<String>> misUsos() async {
    final res = await _api.rpc('mis_campanas_aplicadas', const {});
    if (res is List) {
      return res
          .whereType<Map<dynamic, dynamic>>()
          .map((m) => '${m['campana_id'] ?? ''}')
          .where((e) => e.isNotEmpty)
          .toSet();
    }
    return const {};
  }
}
