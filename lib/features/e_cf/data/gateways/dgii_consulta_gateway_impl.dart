import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:fiscogest_rd/features/e_cf/data/gateways/dgii_auth_client.dart';
import 'package:fiscogest_rd/features/e_cf/data/gateways/dgii_endpoints.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/ambiente_dgii.dart';
import 'package:fiscogest_rd/features/e_cf/domain/ports/dgii_consulta_gateway.dart';

class DgiiConsultaGatewayImpl implements DgiiConsultaGateway {
  DgiiConsultaGatewayImpl({
    required this.ambiente,
    required this.rutaCertificado,
    required this.claveCertificado,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final AmbienteDgii ambiente;
  final String rutaCertificado;
  final String claveCertificado;
  final http.Client _http;

  @override
  Future<DgiiConsultaResultado> consultar(String trackId) async {
    if (!ambiente.permiteEnvio) {
      return const DgiiConsultaResultado(
        ok: false,
        mensaje: 'Ambiente deshabilitado',
      );
    }
    if (trackId.trim().isEmpty) {
      return const DgiiConsultaResultado(ok: false, mensaje: 'TrackId vacío');
    }

    try {
      final auth = DgiiAuthClient(
        ambiente: ambiente,
        rutaCertificado: rutaCertificado,
        claveCertificado: claveCertificado,
        httpClient: _http,
      );
      final tok = await auth.obtenerToken();

      final r = await _http.get(
        Uri.parse(DgiiEndpoints.apiEstadoTrackId(ambiente, trackId)),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${tok.token}',
        },
      );

      if (r.statusCode < 200 || r.statusCode >= 300) {
        return DgiiConsultaResultado(
          ok: false,
          codigo: '${r.statusCode}',
          mensaje: r.body.length > 400 ? r.body.substring(0, 400) : r.body,
          payloadRaw: r.body,
        );
      }

      final map = jsonDecode(r.body) as Map<String, dynamic>;
      final estado = (map['estado'] ?? map['Estado'] ?? '').toString();
      final codigo = (map['codigo'] ?? map['Codigo'])?.toString();
      String? mensaje;
      final mensajes = map['mensajes'] ?? map['Mensajes'];
      if (mensajes is List && mensajes.isNotEmpty) {
        final parts = <String>[];
        for (final m in mensajes) {
          if (m is Map) {
            final v = m['valor'] ?? m['Valor'] ?? m['mensaje'];
            if (v != null && '$v'.isNotEmpty) parts.add('$v');
          } else {
            parts.add('$m');
          }
        }
        mensaje = parts.join(' · ');
      }
      mensaje ??= (map['mensaje'] ?? map['Mensaje'])?.toString();

      return DgiiConsultaResultado(
        ok: true,
        estadoDgii: estado.isEmpty ? null : estado,
        codigo: codigo,
        mensaje: mensaje,
        payloadRaw: r.body,
      );
    } catch (e) {
      return DgiiConsultaResultado(ok: false, mensaje: '$e');
    }
  }
}
