import 'package:http/http.dart' as http;
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';

/// Cliente minimo de Supabase Storage (REST con http, sin SDK).
/// Clave estable por producto: {negocioId}/producto_{id}.jpg
/// Reemplazar foto = PUT upsert sobre la misma clave (1 operacion, sin huerfanos).
class SupabaseStorage {
  SupabaseStorage({http.Client? httpClient})
      : _http = httpClient ?? http.Client();
  final http.Client _http;
  static const bucket = 'catalogo';

  static String claveFotoProducto(String negocioId, int productoId) =>
      '$negocioId/producto_$productoId.jpg';

  static String urlPublica(String clave) =>
      '${SupabaseConfig.url}/storage/v1/object/public/$bucket/$clave';

  /// Sube o reemplaza la foto (upsert). Devuelve la clave estable.
  /// Lanza Exception con statusCode si la politica RLS rechaza la subida.
  Future<String> subir({
    required String negocioId,
    required int productoId,
    required List<int> bytes,
  }) async {
    final clave = claveFotoProducto(negocioId, productoId);
    final uri = Uri.parse(
      '${SupabaseConfig.url}/storage/v1/object/$bucket/$clave',
    );
    final resp = await _http
        .put(
          uri,
            headers: {
              'apikey': SupabaseConfig.anonKey,
              'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
              'Content-Type': 'image/jpeg',
              'x-upsert': 'true',
            },
          body: bytes,
        )
        .timeout(const Duration(seconds: 25));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Storage upload ${resp.statusCode}: ${resp.body}');
    }
    return clave;
  }
}
