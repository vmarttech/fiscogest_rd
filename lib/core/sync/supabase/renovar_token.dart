import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:fiscogest_rd/core/sync/supabase/sesion_nube.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';

/// Renueva el access token con el refresh de GoTrue. No imprime tokens.
class RenovarToken {
  static Future<bool>? _vuelo;

  static Future<bool> asegurar({bool forzar = false}) async {
    final enCurso = _vuelo;
    if (enCurso != null) return enCurso;
    if (!forzar) {
      final jwt = await SesionNube.tokenVigente();
      final exp = await SesionNube.expiraEn();
      final holgado = jwt != null &&
          jwt.isNotEmpty &&
          (exp == null ||
              exp.isAfter(DateTime.now().add(const Duration(minutes: 2))));
      if (holgado) return true;
      if (_vuelo != null) return _vuelo!;
    }
    final vuelo = _ejecutar();
    _vuelo = vuelo;
    try {
      return await vuelo;
    } finally {
      if (identical(_vuelo, vuelo)) _vuelo = null;
    }
  }

  static Future<bool> _ejecutar() async {
    final refresh = await SesionNube.leerRefresh();
    if (refresh == null || refresh.isEmpty) return false;
    final base = SupabaseConfig.url;
    if (base.isEmpty) return false;
    final anon = SupabaseConfig.anonKey;
    try {
      final res = await http
          .post(
            Uri.parse('$base/auth/v1/token?grant_type=refresh_token'),
            headers: {
              'apikey': anon,
              'Authorization': 'Bearer $anon',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'refresh_token': refresh}),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 400 ||
          res.statusCode == 401 ||
          res.statusCode == 403) {
        debugPrint('RenovarToken: rechazado ${res.statusCode}');
        await SesionNube.clear();
        return false;
      }
      if (res.statusCode != 200) {
        debugPrint('RenovarToken: http ${res.statusCode}');
        return false;
      }
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return false;
      final access = decoded['access_token']?.toString() ?? '';
      final nuevo = decoded['refresh_token']?.toString() ?? '';
      final raw = decoded['expires_in'];
      final secs = raw is int
          ? raw
          : raw is num
              ? raw.toInt()
              : int.tryParse('$raw') ?? 3600;
      if (access.isEmpty) return false;
      await SesionNube.guardar(
        token: access,
        expiresInSec: secs,
        refreshToken: nuevo.isEmpty ? null : nuevo,
      );
      debugPrint('RenovarToken: renovado (${secs}s)');
      return true;
    } catch (e) {
      debugPrint('RenovarToken: red $e');
      return false;
    }
  }
}
