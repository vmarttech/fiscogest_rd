import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';

/// Alta y resolución de negocios en Supabase (public.negocios).
class NegocioRemote {
  NegocioRemote({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  Uri get _uri =>
      Uri.parse('${SupabaseConfig.url}/rest/v1/negocios');

  Map<String, String> get _headers => {
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  /// Crea un negocio nuevo y devuelve su UUID.
  Future<String> crear({
    required String nombre,
    String plan = 'demo',
    String estado = 'activa',
  }) async {
    if (!SupabaseConfig.isConfigured) {
      throw StateError('Supabase no configurado');
    }
    final body = {
      'nombre': nombre.trim().isEmpty ? 'Mi negocio' : nombre.trim(),
      'plan': plan,
      'estado': estado,
      'max_dispositivos': 3,
      'max_cajas': 1,
      'ecf_habilitado': false,
      'vitalicia': false,
    };
    final res = await _http.post(
      _uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode >= 300) {
      throw Exception(
        'NegocioRemote.crear: ${res.statusCode} ${res.body}',
      );
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! List || decoded.isEmpty) {
      throw Exception('NegocioRemote.crear: respuesta vacía');
    }
    final first = decoded.first;
    if (first is! Map) {
      throw Exception('NegocioRemote.crear: fila inválida');
    }
    final map = Map<String, dynamic>.from(first);
    final id = map['id']?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('NegocioRemote.crear: sin id');
    }
    debugPrint('NegocioRemote: creado $id ($nombre)');
    return id;
  }

  /// Busca el negocio_id de un username en public.usuarios (sin filtrar por negocio).
  Future<String?> negocioIdDeUsername(String username) async {
    if (!SupabaseConfig.isConfigured) return null;
    final u = username.trim();
    if (u.isEmpty) return null;
    final uri = Uri.parse(
      '${SupabaseConfig.url}/rest/v1/usuarios',
    ).replace(queryParameters: {
      'username': 'eq.$u',
      'select': 'negocio_id,username,activo',
      'limit': '1',
    });
    final res = await _http.get(uri, headers: {
      'apikey': SupabaseConfig.anonKey,
      'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
    });
    if (res.statusCode >= 300) {
      debugPrint('NegocioRemote.negocioIdDeUsername: ${res.statusCode}');
      return null;
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! List || decoded.isEmpty) return null;
    final first = decoded.first;
    if (first is! Map) return null;
    final map = Map<String, dynamic>.from(first);
    final id = map['negocio_id']?.toString();
    if (id == null || id.isEmpty) return null;
    return id;
  }
}
