import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fiscogest_rd/core/sync/supabase/negocio_local.dart';
import 'package:fiscogest_rd/core/sync/supabase/sesion_nube.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';

/// Pide JWT al Edge Function. Nunca lanza: el login local no depende de esto.
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
      final negocioId = await NegocioLocal.getId();
      if (negocioId == null || negocioId.isEmpty) {
        debugPrint('EmitirToken: sin negocio_id');
        return;
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
            body: jsonEncode({
              'username': username.trim(),
              'password': password,
              'negocio_id': negocioId,
            }),
          )
          .timeout(const Duration(seconds: 4));
      if (res.statusCode >= 300) {
        debugPrint('EmitirToken: ${res.statusCode} ${res.body}');
        await SesionNube.clear();
        return;
      }
      final map = jsonDecode(res.body);
      if (map is! Map) return;
      final token = map['token']?.toString() ?? '';
      final exp = (map['expires_in'] as num?)?.toInt() ?? 43200;
      if (token.isEmpty) return;
      await SesionNube.guardar(token: token, expiresInSec: exp);
      debugPrint('EmitirToken: JWT guardado (${exp}s)');
    } catch (e) {
      debugPrint('EmitirToken: $e');
    }
  }
}
