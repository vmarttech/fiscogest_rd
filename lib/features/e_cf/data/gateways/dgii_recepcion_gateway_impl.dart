import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:fiscogest_rd/features/e_cf/data/gateways/dgii_auth_client.dart';
import 'package:fiscogest_rd/features/e_cf/data/gateways/dgii_endpoints.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/ambiente_dgii.dart';
import 'package:fiscogest_rd/features/e_cf/domain/ports/dgii_recepcion_gateway.dart';

class DgiiRecepcionGatewayImpl implements DgiiRecepcionGateway {
  DgiiRecepcionGatewayImpl({
    required this.ambiente,
    required this.rutaCertificado,
    required this.claveCertificado,
    required this.rncEmisor,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final AmbienteDgii ambiente;
  final String rutaCertificado;
  final String claveCertificado;
  final String rncEmisor;
  final http.Client _http;

  @override
  Future<DgiiRecepcionResultado> enviar(String xmlFirmado) =>
      enviarConNombre(xmlFirmado, null);

  Future<DgiiRecepcionResultado> enviarConNombre(
    String xmlFirmado,
    String? nombreArchivo,
  ) async {
    if (!ambiente.permiteEnvio) {
      return const DgiiRecepcionResultado(
        ok: false,
        mensaje: 'Ambiente deshabilitado',
      );
    }
    if (xmlFirmado.trim().isEmpty) {
      return const DgiiRecepcionResultado(ok: false, mensaje: 'XML vacío');
    }

    try {
      final auth = DgiiAuthClient(
        ambiente: ambiente,
        rutaCertificado: rutaCertificado,
        claveCertificado: claveCertificado,
        httpClient: _http,
      );
      final tok = await auth.obtenerToken();

      final fileName = (nombreArchivo ?? _nombreDesdeXml(xmlFirmado)).trim();
      final tmp = await Directory.systemTemp.createTemp('dgii_rec_');
      try {
        final f = File('${tmp.path}/$fileName');
        await f.writeAsString(xmlFirmado, flush: true);

        final req = http.MultipartRequest(
          'POST',
          Uri.parse(DgiiEndpoints.apiRecepcion(ambiente)),
        );
        req.headers['Accept'] = 'application/json';
        req.headers['Authorization'] = 'Bearer ${tok.token}';
        req.files.add(
          await http.MultipartFile.fromPath('xml', f.path, filename: fileName),
        );

        final streamed = await _http.send(req);
        final body = await streamed.stream.bytesToString();

        if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
          return DgiiRecepcionResultado(
            ok: false,
            codigo: '${streamed.statusCode}',
            mensaje: body.length > 500 ? body.substring(0, 500) : body,
          );
        }

        String? trackId;
        String? codigo;
        String? mensaje;
        try {
          final map = jsonDecode(body) as Map<String, dynamic>;
          trackId =
              (map['trackId'] ?? map['TrackId'] ?? map['trackID'])?.toString();
          codigo = (map['codigo'] ?? map['Codigo'])?.toString();
          mensaje =
              (map['mensaje'] ?? map['Mensaje'] ?? map['error'])?.toString();
        } catch (_) {
          final m = RegExp(
            r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
          ).firstMatch(body);
          trackId = m?.group(0);
          mensaje = body.length > 200 ? body.substring(0, 200) : body;
        }

        if (trackId == null || trackId.isEmpty) {
          return DgiiRecepcionResultado(
            ok: false,
            codigo: codigo,
            mensaje: mensaje ?? 'Sin TrackId: $body',
          );
        }

        return DgiiRecepcionResultado(
          ok: true,
          trackId: trackId,
          codigo: codigo,
          mensaje: mensaje ?? 'Recibido',
        );
      } finally {
        try {
          await tmp.delete(recursive: true);
        } catch (_) {}
      }
    } catch (e) {
      return DgiiRecepcionResultado(ok: false, mensaje: '$e');
    }
  }

  String _nombreDesdeXml(String xml) {
    final rnc =
        RegExp(r'<RNCEmisor>([^<]+)</RNCEmisor>').firstMatch(xml)?.group(1) ??
            rncEmisor;
    final encf =
        RegExp(r'<eNCF>([^<]+)</eNCF>').firstMatch(xml)?.group(1) ?? 'ENCF';
    return '${rnc.replaceAll(RegExp(r'\D'), '')}$encf.xml';
  }
}
