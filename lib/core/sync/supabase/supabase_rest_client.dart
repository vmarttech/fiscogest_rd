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

  Map<String, String> get _headers => {
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates,return=minimal',
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
      headers: _headers,
      body: jsonEncode(rows),
    );
    if (res.statusCode >= 300) {
      throw Exception(
        'Supabase upsert $table: ${res.statusCode} ${res.body}',
      );
    }
  }
}
