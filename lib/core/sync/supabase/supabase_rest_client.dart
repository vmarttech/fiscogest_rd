import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';

class SupabaseRestClient {
  SupabaseRestClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  Uri _uri(String table, [Map<String, String>? query]) {
    final t = table.toLowerCase();
    return Uri.parse('${SupabaseConfig.url}/rest/v1/$t')
        .replace(queryParameters: query);
  }

  Map<String, String> get _headersUpsert => {
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates,return=minimal',
      };

  Map<String, String> get _headersSelect => {
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  Future<void> upsert({
    required String table,
    required List<Map<String, dynamic>> rows,
    required String onConflict,
  }) async {
    if (!SupabaseConfig.isConfigured || rows.isEmpty) return;
    final uri = _uri(table).replace(
      queryParameters: {'on_conflict': onConflict},
    );
    final res = await _http.post(
      uri,
      headers: _headersUpsert,
      body: jsonEncode(rows),
    );
    if (res.statusCode >= 300) {
      throw Exception(
        'Supabase upsert $table: ${res.statusCode} ${res.body}',
      );
    }
  }

  /// GET /rest/v1/{table}?col=eq.valor
  /// [filters] ejemplo: {'negocio_id': 'eq.<uuid>'}
  Future<List<Map<String, dynamic>>> select({
    required String table,
    Map<String, String>? filters,
    String? order,
  }) async {
    if (!SupabaseConfig.isConfigured) return [];

    final query = <String, String>{};
    if (filters != null) query.addAll(filters);
    if (order != null) query['order'] = order;

    final uri = _uri(table, query.isEmpty ? null : query);
    final res = await _http.get(uri, headers: _headersSelect);

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
