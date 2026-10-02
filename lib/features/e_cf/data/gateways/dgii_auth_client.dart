import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:fiscogest_rd/features/e_cf/data/gateways/dgii_endpoints.dart';
import 'package:fiscogest_rd/features/e_cf/data/gateways/dgii_token_cache.dart';
import 'package:fiscogest_rd/features/e_cf/data/xml/ecfe_signer_impl.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/ambiente_dgii.dart';

class DgiiToken {
  const DgiiToken({required this.token, this.expira});
  final String token;
  final DateTime? expira;
}

class DgiiAuthClient {
  DgiiAuthClient({
    required this.ambiente,
    required this.rutaCertificado,
    required this.claveCertificado,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final AmbienteDgii ambiente;
  final String rutaCertificado;
  final String claveCertificado;
  final http.Client _http;

  Future<DgiiToken> obtenerToken({bool forzar = false}) async {
    if (!ambiente.permiteEnvio) {
      throw StateError('Ambiente no permite autenticación DGII');
    }
    if (!forzar) {
      final cached = DgiiTokenCache.instance.get(ambiente);
      if (cached != null) return cached;
    }

    final rSeed = await _http.get(
      Uri.parse(DgiiEndpoints.apiSemilla(ambiente)),
      headers: {'Accept': 'application/xml, text/xml, */*'},
    );
    if (rSeed.statusCode < 200 || rSeed.statusCode >= 300) {
      throw StateError(
        'Semilla DGII HTTP ${rSeed.statusCode}: ${_clip(rSeed.body)}',
      );
    }
    final semillaXml = rSeed.body.trim();
    if (semillaXml.isEmpty) throw StateError('Semilla DGII vacía');

    final signer = EcfeSignerImpl(
      rutaCertificado: rutaCertificado,
      claveCertificado: claveCertificado,
    );
    final semillaFirmada = await signer.firmar(semillaXml);

    final tmp = await Directory.systemTemp.createTemp('dgii_auth_');
    try {
      final f = File('${tmp.path}/semilla.xml');
      await f.writeAsString(semillaFirmada, flush: true);

      final req = http.MultipartRequest(
        'POST',
        Uri.parse(DgiiEndpoints.apiValidarSemilla(ambiente)),
      );
      req.headers['Accept'] = 'application/json';
      req.files.add(
        await http.MultipartFile.fromPath('xml', f.path, filename: 'semilla.xml'),
      );

      final streamed = await _http.send(req);
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        throw StateError(
          'ValidarSemilla HTTP ${streamed.statusCode}: ${_clip(body)}',
        );
      }

      final map = jsonDecode(body) as Map<String, dynamic>;
      final token = (map['token'] ?? map['Token'] ?? '').toString();
      if (token.isEmpty) throw StateError('Respuesta sin token: $body');
      DateTime? expira;
      final expRaw = map['expira'] ?? map['Expira'];
      if (expRaw != null) expira = DateTime.tryParse(expRaw.toString());
      final tok = DgiiToken(token: token, expira: expira);
      DgiiTokenCache.instance.put(ambiente, tok);
      return tok;
    } finally {
      try {
        await tmp.delete(recursive: true);
      } catch (_) {}
    }
  }

  static String _clip(String s) => s.length > 300 ? s.substring(0, 300) : s;
}
