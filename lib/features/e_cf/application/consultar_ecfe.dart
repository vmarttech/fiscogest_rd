import 'package:fiscogest_rd/features/e_cf/data/gateways/dgii_consulta_gateway_impl.dart';
import 'package:fiscogest_rd/features/e_cf/data/repositories/ecfe_repository.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/estado_ecf_interno.dart';

class ConsultarEcfeResultado {
  const ConsultarEcfeResultado({
    required this.ok,
    this.estado,
    this.estadoDgii,
    this.mensaje,
    this.errores = const [],
  });

  final bool ok;
  final EstadoEcfInterno? estado;
  final String? estadoDgii;
  final String? mensaje;
  final List<String> errores;
}

class ConsultarEcfe {
  ConsultarEcfe({required this.repo});
  final EcfeRepository repo;

  Future<ConsultarEcfeResultado> call({required int documentoId}) async {
    try {
      final cfg = await repo.obtenerConfig();
      if (!cfg.listoParaPipeline) {
        return const ConsultarEcfeResultado(
          ok: false,
          errores: ['Módulo e-CF no listo (habilitado + ambiente + RNC)'],
        );
      }
      if (!cfg.tieneCertificado) {
        return const ConsultarEcfeResultado(
          ok: false,
          errores: ['Certificado .p12 y clave requeridos'],
        );
      }

      final doc = await repo.obtenerPorId(documentoId);
      if (doc == null) {
        return const ConsultarEcfeResultado(
          ok: false,
          errores: ['Documento no encontrado'],
        );
      }

      final trackId = (doc.trackId ?? '').trim();
      if (trackId.isEmpty) {
        return const ConsultarEcfeResultado(
          ok: false,
          errores: ['Sin TrackId: envía el documento a la DGII primero'],
        );
      }

      final gw = DgiiConsultaGatewayImpl(
        ambiente: cfg.ambiente,
        rutaCertificado: cfg.rutaCertificado,
        claveCertificado: cfg.claveCertificado,
      );
      final res = await gw.consultar(trackId);

      if (!res.ok) {
        final errorAnterior = doc.ultimoError ?? '';
        final conservaIncertidumbre = errorAnterior.contains(
          '[ENVIO_DGII_INCIERTO]',
        );
        final errorConsulta = res.mensaje ?? 'Consulta fallida';

        await repo.actualizarEstado(
          id: documentoId,
          estado: doc.estado,
          codigoRespuesta: res.codigo,
          mensajeDgii: res.mensaje,
          ultimoError: conservaIncertidumbre
              ? '[ENVIO_DGII_INCIERTO] $errorConsulta'
              : res.mensaje,
        );
        await repo.registrarEvento(
          documentoId: documentoId,
          paso: 'consultar_estado',
          ok: false,
          detalle: res.mensaje,
        );
        return ConsultarEcfeResultado(
          ok: false,
          estado: doc.estado,
          mensaje: res.mensaje,
          errores: [res.mensaje ?? 'Consulta fallida'],
        );
      }

      final interno = mapearEstadoDgii(res.estadoDgii, res.codigo);

      // Una respuesta HTTP correcta no garantiza un estado fiscal concluyente.
      // Si DGII devuelve un estado desconocido, no alterar el estado guardado.
      if (interno == null) {
        final detalle =
            (res.estadoDgii == null || res.estadoDgii!.trim().isEmpty)
            ? 'DGII no devolvió un estado fiscal reconocible'
            : 'Estado DGII no reconocido: ${res.estadoDgii}';

        await repo.registrarEvento(
          documentoId: documentoId,
          paso: 'consultar_estado',
          ok: false,
          detalle: detalle,
        );

        return ConsultarEcfeResultado(
          ok: false,
          estado: doc.estado,
          estadoDgii: res.estadoDgii,
          mensaje: res.mensaje,
          errores: [detalle],
        );
      }

      final errorAnterior = doc.ultimoError ?? '';
      final esEstadoTerminalConfirmado =
          interno == EstadoEcfInterno.aceptado ||
          interno == EstadoEcfInterno.aceptadoObservacion ||
          interno == EstadoEcfInterno.rechazado;
      final conservaIncertidumbre =
          errorAnterior.contains('[ENVIO_DGII_INCIERTO]') &&
          !esEstadoTerminalConfirmado;

      await repo.actualizarEstado(
        id: documentoId,
        estado: interno,
        codigoRespuesta: res.codigo,
        mensajeDgii: res.mensaje ?? res.estadoDgii,
        ultimoError: conservaIncertidumbre
            ? errorAnterior
            : interno == EstadoEcfInterno.rechazado
            ? (res.mensaje ?? res.estadoDgii)
            : null,
      );
      // Si la DGII envía código de seguridad en el JSON, persistirlo
      final codOficial = _extraerCodigoSeguridad(res.payloadRaw);
      if (codOficial != null) {
        await repo.guardarCodigoSeguridad(
          id: documentoId,
          codigoSeguridad: codOficial,
        );
      }
      await repo.registrarEvento(
        documentoId: documentoId,
        paso: 'consultar_estado',
        ok:
            interno.esTerminalExito ||
            interno == EstadoEcfInterno.enProceso ||
            interno == EstadoEcfInterno.enviado,
        detalle:
            '${res.estadoDgii ?? interno.etiqueta}${res.mensaje != null ? ' · ${res.mensaje}' : ''}',
      );

      return ConsultarEcfeResultado(
        ok: true,
        estado: interno,
        estadoDgii: res.estadoDgii,
        mensaje: res.mensaje,
      );
    } catch (e) {
      try {
        await repo.registrarEvento(
          documentoId: documentoId,
          paso: 'consultar_estado',
          ok: false,
          detalle: '$e',
        );
      } catch (_) {}
      return ConsultarEcfeResultado(ok: false, errores: ['$e']);
    }
  }

  static String? _extraerCodigoSeguridad(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final m = RegExp(
      r'"[Cc]odigo[_]?[Ss]eguridad"\s*:\s*"([^"]+)"',
    ).firstMatch(raw);
    final v = m?.group(1)?.trim();
    if (v != null && v.isNotEmpty) return v.toUpperCase();
    return null;
  }

  /// Solo traduce estados fiscales reconocidos por su texto.
  /// null significa que la respuesta no permite concluir el estado.
  static EstadoEcfInterno? mapearEstadoDgii(
    String? estadoDgii,
    String? codigo,
  ) {
    final e = (estadoDgii ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');

    if (e.isEmpty) return null;

    if (e.contains('rechaz')) {
      return EstadoEcfInterno.rechazado;
    }

    if (e.contains('aceptado cond') ||
        e.contains('aceptado con obs') ||
        e.contains('aceptado con observ') ||
        e.contains('aceptado con objec') ||
        e.contains('aceptado con incidencia') ||
        e.contains('aceptado con observación') ||
        e.contains('aceptado con observacion')) {
      return EstadoEcfInterno.aceptadoObservacion;
    }

    if (e == 'aceptado' ||
        e == 'aceptada' ||
        e == 'aprobado' ||
        e == 'aprobada') {
      return EstadoEcfInterno.aceptado;
    }

    if (e.contains('en proceso') ||
        e == 'proceso' ||
        e.contains('recibido') ||
        e == 'enviado') {
      return EstadoEcfInterno.enProceso;
    }

    // No inferir aceptación o rechazo a partir de códigos no verificados.
    return null;
  }
}
