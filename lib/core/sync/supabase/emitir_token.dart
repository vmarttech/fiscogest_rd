import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fiscogest_rd/core/sync/supabase/negocio_local.dart';
import 'package:fiscogest_rd/core/sync/supabase/sesion_nube.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';

/// Pide JWT al Edge Function.
///
/// Equipo nuevo (sin negocio_id local): el edge busca el usuario en
/// public.usuarios, valida la clave y devuelve negocio_id + token.
/// Luego persistimos negocio_id aquí para pull/push.
class EmitirToken {
  static Future<void> trasLogin({
    required String username,
    required String password,
  }) async {
    try {
      if (!SupabaseConfig.isConfigured) return;
      if (!await SupabaseConfig.hayRed()) {
        debugPrint('EmitirToken: sin red');
        return;
      }

      final negocioHint = await NegocioLocal.getId();
      final body = <String, dynamic>{
        'username': username.trim(),
        'password': password,
      };
      // Solo como filtro opcional si este equipo ya está vinculado
      if (negocioHint != null && negocioHint.isNotEmpty) {
        body['negocio_id'] = negocioHint;
      }

      final uri = Uri.parse(
        '${SupabaseConfig.url}/functions/v1/emitir-token',
      );
      final res = await http
          .post(
            uri,
            headers: {
              'apikey': SupabaseConfig.anonKey,
              'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode >= 300) {
        debugPrint('EmitirToken: ${res.statusCode} ${res.body}');
        await SesionNube.clear();
        return;
      }

      final map = jsonDecode(res.body);
      if (map is! Map) return;

      final token = map['token']?.toString() ?? '';
      final exp = (map['expires_in'] as num?)?.toInt() ?? 43200;
      if (token.isEmpty) {
        debugPrint('EmitirToken: respuesta sin token');
        return;
      }

      // Clave del arreglo global: vincular negocio desde la nube
      final remoteNegocio = map['negocio_id']?.toString().trim() ?? '';
      if (remoteNegocio.isNotEmpty) {
        await NegocioLocal.setId(remoteNegocio);
        debugPrint('EmitirToken: negocio_id=$remoteNegocio');
      } else {
        debugPrint('EmitirToken: JWT OK pero sin negocio_id en respuesta');
      }

      await SesionNube.guardar(
        token: token,
        expiresInSec: exp,
        refreshToken: map['refresh_token']?.toString(),
      );
      final refreshOk =
          (map['refresh_token']?.toString() ?? '').isNotEmpty;
      debugPrint(
        'EmitirToken: JWT guardado${refreshOk ? '' : ' SIN refresh'} (${exp}s)',
      );
    } catch (e) {
      debugPrint('EmitirToken: $e');
    }
  }
}
