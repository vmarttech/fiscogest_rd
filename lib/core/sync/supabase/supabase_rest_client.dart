import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:fiscogest_rd/core/sync/supabase/sesion_nube.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';

class SupabaseRestClient {
  SupabaseRestClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;
  static const _timeout = Duration(seconds: 4);

  static const _tablasConNegocio = {
    'productos',
    'clientes',
    'ventas',
    'ventas_detalle',
    'caja_sesiones',
    'caja_movimientos',
    'fios',
    'usuarios',
    'dispositivos_licencia',
  };

  void _assertNegocio(String table, Map<String, String>? filters) {
    if (!_tablasConNegocio.contains(table.toLowerCase())) return;
    final f = filters?['negocio_id'] ?? '';
    if (!f.startsWith('eq.') || f.length < 8) {
      throw Exception('Sync: $table sin negocio_id');
    }
  }

  Uri _uri(String table, [Map<String, String>? query]) {
    final t = table.toLowerCase();
    return Uri.parse('${SupabaseConfig.url}/rest/v1/$t')
        .replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers({
    required bool upsert,
    required bool usarJwt,
  }) async {
    var bearer = SupabaseConfig.anonKey;
    if (usarJwt) {
      final jwt = await SesionNube.tokenVigente();
      if (jwt != null && jwt.isNotEmpty) bearer = jwt;
    }
    debugPrint(
      'REST headers jwt=${usarJwt && bearer != SupabaseConfig.anonKey} prefix=${bearer.length >= 8 ? bearer.substring(0, 8) : bearer}',
    );
    return {
      'apikey': SupabaseConfig.anonKey,
      'Authorization': 'Bearer $bearer',
      'Content-Type': 'application/json',
      'Prefer': upsert
          ? 'resolution=merge-duplicates,return=minimal'
          : 'return=representation',
    };
  }

  Future<http.Response> _post(Uri uri, String body, {required bool usarJwt}) async {
    final h = await _headers(upsert: true, usarJwt: usarJwt);
    return _http.post(uri, headers: h, body: body).timeout(_timeout);
  }

  Future<http.Response> _get(Uri uri, {required bool usarJwt}) async {
    final h = await _headers(upsert: false, usarJwt: usarJwt);
    return _http.get(uri, headers: h).timeout(_timeout);
  }

  Future<void> upsert({
    required String table,
    required List<Map<String, dynamic>> rows,
    required String onConflict,
  }) async {
    if (!SupabaseConfig.isConfigured || rows.isEmpty) return;
    for (final row in rows) {
      final n = row['negocio_id']?.toString() ?? '';
      if (n.isEmpty && _tablasConNegocio.contains(table.toLowerCase())) {
        throw Exception('Sync upsert $table sin negocio_id');
      }
    }
    final uri = _uri(table).replace(
      queryParameters: {'on_conflict': onConflict},
    );
    final body = jsonEncode(rows);
    var res = await _post(uri, body, usarJwt: true);
    if (res.statusCode == 401 || res.statusCode == 403) {
      res = await _post(uri, body, usarJwt: false);
    }
    if (res.statusCode >= 300) {
      throw Exception(
        'Supabase upsert $table: ${res.statusCode} ${res.body}',
      );
    }
  }

  /// GET filtrado; obliga negocio_id en tablas de negocio.
  Future<List<Map<String, dynamic>>> select({
    required String table,
    Map<String, String>? filters,
    String? order,
  }) async {
    if (!SupabaseConfig.isConfigured) return [];
    _assertNegocio(table, filters);
    final query = <String, String>{};
    if (filters != null) query.addAll(filters);
    if (order != null) query['order'] = order;
    final uri = _uri(table, query.isEmpty ? null : query);
    var res = await _get(uri, usarJwt: true);
    if (res.statusCode == 401 || res.statusCode == 403) {
      res = await _get(uri, usarJwt: false);
    }
    if (res.statusCode >= 300) {
      throw Exception(
        'Supabase select $table: ${res.statusCode} ${res.body}',
      );
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! List) return [];
    return decoded
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}
