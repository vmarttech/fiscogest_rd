import 'dart:convert';

import 'package:http/http.dart' as http;

/// Resultado de consulta RNC/cédula.
/// Nota: la DGII no ofrece API pública oficial; se usa un servicio de terceros.
class RncContribuyente {
  const RncContribuyente({
    required this.rnc,
    required this.nombre,
    this.nombreComercial,
    this.estado,
  });

  final String rnc;
  final String nombre;
  final String? nombreComercial;
  final String? estado;
}

class DgiiRncConsultaService {
  DgiiRncConsultaService({
    http.Client? client,
    this.baseUrl = 'https://rnc.megaplus.com.do',
    this.timeout = const Duration(seconds: 12),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  static String normalizar(String raw) =>
      raw.replaceAll(RegExp(r'[^\d]'), '');

  static bool esFormatoValido(String raw) {
    final d = normalizar(raw);
    return d.length == 9 || d.length == 11;
  }

  Future<RncContribuyente> consultar(String rncOCedula) async {
    final rnc = normalizar(rncOCedula);
    if (!esFormatoValido(rnc)) {
      throw Exception('RNC (9 dígitos) o cédula (11 dígitos)');
    }

    final uri = Uri.parse('$baseUrl/api/consulta').replace(
      queryParameters: {'rnc': rnc},
    );

    late final http.Response res;
    try {
      res = await _client.get(uri).timeout(timeout);
    } on Exception catch (e) {
      throw Exception(
        'Sin conexión o servicio RNC no disponible. ($e)',
      );
    }

    if (res.statusCode == 404) {
      throw Exception('RNC/cédula no encontrado en el padrón');
    }
    if (res.statusCode != 200) {
      throw Exception(
        'No se pudo consultar el RNC (código ${res.statusCode})',
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw Exception('Respuesta RNC inválida');
    }
    final map = Map<String, dynamic>.from(decoded);
    if (map['error'] == true) {
      throw Exception(map['mensaje']?.toString() ?? 'RNC no encontrado');
    }

    final nombre = (map['nombre_razon_social'] ??
            map['nombre'] ??
            map['razon_social'] ??
            '')
        .toString()
        .trim();
    if (nombre.isEmpty) {
      throw Exception('RNC no encontrado');
    }

    return RncContribuyente(
      rnc: normalizar(
        (map['rnc_consultado'] ?? map['cedula_rnc'] ?? rnc).toString(),
      ),
      nombre: nombre,
      nombreComercial: map['nombre_comercial']?.toString(),
      estado: map['estado']?.toString(),
    );
  }

  void dispose() => _client.close();
}
