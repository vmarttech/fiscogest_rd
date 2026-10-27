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
    this.requestTimeout = const Duration(seconds: 45),
  }) : _http = httpClient ?? http.Client();

  final AmbienteDgii ambiente;
  final String rutaCertificado;
  final String claveCertificado;
  final String rncEmisor;
  final http.Client _http;

  /// Tiempo máximo permitido para cada fase de comunicación con DGII.
  final Duration requestTimeout;

  @override
  Future<DgiiRecepcionResultado> enviar(String xmlFirmado) =>
      enviarConNombre(xmlFirmado, null);

  Future<DgiiRecepcionResultado> enviarConNombre(
    String xmlFirmado,
    String? nombreArchivo, {
    bool rfce = false,
  }) async {
    if (!ambiente.permiteEnvio) {
      return const DgiiRecepcionResultado(
        ok: false,
        mensaje: 'Ambiente deshabilitado',
      );
    }
    if (xmlFirmado.trim().isEmpty) {
      return const DgiiRecepcionResultado(ok: false, mensaje: 'XML vacío');
    }

    var solicitudRecepcionIniciada = false;

    try {
      final auth = DgiiAuthClient(
        ambiente: ambiente,
        rutaCertificado: rutaCertificado,
        claveCertificado: claveCertificado,
        httpClient: _http,
      );
      final tok = await auth.obtenerToken().timeout(requestTimeout);

      final fileName = (nombreArchivo ?? _nombreDesdeXml(xmlFirmado)).trim();
      final tmp = await Directory.systemTemp.createTemp('dgii_rec_');
      try {
        final f = File('${tmp.path}/$fileName');
        await f.writeAsString(xmlFirmado, flush: true);

        final req = http.MultipartRequest(
          'POST',
          Uri.parse(
            rfce
                ? DgiiEndpoints.apiRecepcionFc(ambiente)
                : DgiiEndpoints.apiRecepcion(ambiente),
          ),
        );
        req.headers['Accept'] = 'application/json';
        req.headers['Authorization'] = 'Bearer ${tok.token}';
        req.files.add(
          await http.MultipartFile.fromPath('xml', f.path, filename: fileName),
        );

        solicitudRecepcionIniciada = true;
        final streamed = await _http.send(req).timeout(requestTimeout);
        final body = await streamed.stream.bytesToString().timeout(
          requestTimeout,
        );
        if (rfce) return _resultadoRfce(streamed.statusCode, body);

        if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
          return DgiiRecepcionResultado(
            ok: false,
            codigo: '${streamed.statusCode}',
            mensaje: body.length > 500 ? body.substring(0, 500) : body,
            resultadoIncierto: streamed.statusCode >= 500,
          );
        }

        String? trackId;
        String? codigo;
        String? mensaje;
        try {
          final map = jsonDecode(body) as Map<String, dynamic>;
          trackId = (map['trackId'] ?? map['TrackId'] ?? map['trackID'])
              ?.toString();
          codigo = (map['codigo'] ?? map['Codigo'])?.toString();
          mensaje = (map['mensaje'] ?? map['Mensaje'] ?? map['error'])
              ?.toString();
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
            resultadoIncierto: true,
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
      return DgiiRecepcionResultado(
        ok: false,
        mensaje: '$e',
        resultadoIncierto: solicitudRecepcionIniciada,
      );
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

  DgiiRecepcionResultado _resultadoRfce(int status, String body) {
    final cuerpo = body.length > 500 ? body.substring(0, 500) : body;

    if (status < 200 || status >= 300) {
      return DgiiRecepcionResultado(
        ok: false,
        codigo: '$status',
        mensaje: cuerpo,
        resultadoIncierto: status >= 500,
      );
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return DgiiRecepcionResultado(
          ok: false,
          mensaje: cuerpo,
          resultadoIncierto: true,
        );
      }

      final estadoOriginal = (decoded['estado'] ?? '').toString().trim();
      final codigo = (decoded['codigo'] ?? '').toString();

      var mensaje = estadoOriginal;
      final mensajes = decoded['mensajes'];
      if (mensajes is List && mensajes.isNotEmpty && mensajes.first is Map) {
        final primero = mensajes.first as Map;
        mensaje = (primero['valor'] ?? primero['mensaje'] ?? estadoOriginal)
            .toString();
      }

      final normalizado = estadoOriginal
          .toLowerCase()
          .replaceAll(RegExp(r'[_-]+'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final String? estadoCanonico;
      if (normalizado == 'aceptado') {
        estadoCanonico = 'aceptado';
      } else if (normalizado == 'aceptado condicional' ||
          normalizado == 'aceptado condicionalmente') {
        estadoCanonico = 'aceptado condicional';
      } else if (normalizado == 'rechazado') {
        estadoCanonico = 'rechazado';
      } else {
        estadoCanonico = null;
      }

      final aceptado =
          estadoCanonico == 'aceptado' ||
          estadoCanonico == 'aceptado condicional';
      final rechazado = estadoCanonico == 'rechazado';

      return DgiiRecepcionResultado(
        ok: aceptado,
        codigo: codigo,
        mensaje: mensaje.isEmpty ? estadoOriginal : mensaje,
        estadoDgii: estadoCanonico,
        resultadoIncierto: !aceptado && !rechazado,
      );
    } catch (_) {
      return DgiiRecepcionResultado(
        ok: false,
        mensaje: cuerpo,
        resultadoIncierto: true,
      );
    }
  }
}
