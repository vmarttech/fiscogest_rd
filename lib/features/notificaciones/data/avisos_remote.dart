// [AVISOS_FASE1] Cliente RPC de avisos (sin service key en el cliente).
import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';
import 'package:fiscogest_rd/features/notificaciones/domain/aviso_remoto.dart';

class AvisosRemote {
  AvisosRemote({SupabaseRestClient? client})
    : _client = client ?? SupabaseRestClient();

  final SupabaseRestClient _client;

  List<AvisoRemoto> _filas(dynamic res) {
    if (res is List) {
      return res
          .whereType<Map<dynamic, dynamic>>()
          .map((m) => AvisoRemoto.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    if (res is Map && res['data'] is List) {
      final data = res['data'] as List<dynamic>;
      return data
          .whereType<Map<dynamic, dynamic>>()
          .map((m) => AvisoRemoto.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return const <AvisoRemoto>[];
  }

  Future<List<AvisoRemoto>> listar({bool soloNoLeidos = false}) async {
    final res = await _client.rpc('avisos_listar', {
      'p_solo_no_leidos': soloNoLeidos,
    });
    return _filas(res);
  }

  Future<int> noLeidos() async {
    final res = await _client.rpc('avisos_no_leidos', const {});
    if (res is num) return res.toInt();
    if (res is String) return int.tryParse(res) ?? 0;
    return 0;
  }

  Future<bool> marcarLeido(String avisoId) async {
    final res = await _client.rpc('aviso_marcar_leido', {
      'p_aviso_id': avisoId,
    });
    return res == true;
  }

  Future<int> marcarTodosLeidos() async {
    final res = await _client.rpc('aviso_marcar_todos_leidos', const {});
    if (res is num) return res.toInt();
    return 0;
  }

  /// Solo administradores; la autorización real está en admin_enviar_aviso (42501 si no).
  Future<int> enviar({
    required String tipo,
    required String titulo,
    required String mensaje,
    String segmento = 'todos',
    String? negocioId,
    String? plan,
    String prioridad = 'normal',
  }) async {
    final res = await _client.rpc('admin_enviar_aviso', {
      'p_tipo': tipo,
      'p_titulo': titulo,
      'p_mensaje': mensaje,
      'p_segmento': segmento,
      'p_negocio_id': negocioId,
      'p_plan': plan,
      'p_prioridad': prioridad,
    });
    if (res is num) return res.toInt();
    return 0;
  }
}
