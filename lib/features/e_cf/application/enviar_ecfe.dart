import 'package:fiscogest_rd/features/e_cf/data/gateways/dgii_recepcion_gateway_impl.dart';
import 'package:fiscogest_rd/features/e_cf/data/repositories/ecfe_repository.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/estado_ecf_interno.dart';

class EnviarEcfeResultado {
  const EnviarEcfeResultado({
    required this.ok,
    this.trackId,
    this.errores = const [],
    this.yaEnviado = false,
  });

  final bool ok;
  final String? trackId;
  final List<String> errores;

  /// True si no se reenvió porque ya había TrackId.
  final bool yaEnviado;
}

class EnviarEcfe {
  EnviarEcfe({required this.repo});
  final EcfeRepository repo;

  /// Envía el XML firmado a recepción DGII.
  ///
  /// [forzarReenvio]: solo para casos excepcionales (TrackId inválido).
  /// Por defecto, si ya hay TrackId, no vuelve a enviar.
  Future<EnviarEcfeResultado> call({
    required int documentoId,
    bool forzarReenvio = false,
  }) async {
    const marcaEnvioIncierto = '[ENVIO_DGII_INCIERTO]';
    var resultadoRecepcionIncierto = false;

    try {
      final cfg = await repo.obtenerConfig();
      if (!cfg.listoParaPipeline) {
        return const EnviarEcfeResultado(
          ok: false,
          errores: ['Módulo e-CF no listo (habilitado + ambiente + RNC)'],
        );
      }
      if (!cfg.tieneCertificado) {
        return const EnviarEcfeResultado(
          ok: false,
          errores: ['Certificado .p12 y clave requeridos'],
        );
      }

      final doc = await repo.obtenerPorId(documentoId);
      if (doc == null) {
        return const EnviarEcfeResultado(
          ok: false,
          errores: ['Documento no encontrado'],
        );
      }

      final trackExistente = (doc.trackId ?? '').trim();

      // La incertidumbre siempre bloquea el envío, incluso si se solicita
      // forzarReenvio o el documento ya tiene un TrackId guardado.
      if ((doc.ultimoError ?? '').contains(marcaEnvioIncierto)) {
        return const EnviarEcfeResultado(
          ok: false,
          errores: [
            'Recepción DGII incierta. No se reenvió para evitar duplicados. '
                'Consulta el estado con DGII y verifica el resultado antes '
                'de cualquier acción excepcional.',
          ],
        );
      }

      if (trackExistente.isNotEmpty && !forzarReenvio) {
        await repo.registrarEvento(
          documentoId: documentoId,
          paso: 'enviar_recepcion',
          ok: true,
          detalle:
              'Omitido: ya tiene TrackId $trackExistente (use forzar si aplica)',
        );
        return EnviarEcfeResultado(
          ok: true,
          trackId: trackExistente,
          yaEnviado: true,
        );
      }

      if (doc.estado == EstadoEcfInterno.aceptado ||
          doc.estado == EstadoEcfInterno.aceptadoObservacion ||
          doc.estado == EstadoEcfInterno.anulado) {
        return EnviarEcfeResultado(
          ok: false,
          errores: [
            'Estado ${doc.estado.etiqueta}: no se puede enviar de nuevo',
          ],
        );
      }

      // Enviado/en proceso sin TrackId es inconsistente → permitir reintento.
      final puedeEnviar =
          doc.estado == EstadoEcfInterno.firmado ||
          doc.estado == EstadoEcfInterno.errorTecnico ||
          (doc.estado == EstadoEcfInterno.enviado && trackExistente.isEmpty) ||
          (doc.estado == EstadoEcfInterno.enProceso &&
              trackExistente.isEmpty) ||
          (forzarReenvio &&
              (doc.estado == EstadoEcfInterno.enviado ||
                  doc.estado == EstadoEcfInterno.enProceso ||
                  doc.estado == EstadoEcfInterno.rechazado));

      if (!puedeEnviar) {
        return EnviarEcfeResultado(
          ok: false,
          errores: [
            'Estado ${doc.estado.etiqueta}: se requiere XML firmado '
                'sin TrackId previo (o forzar reenvío)',
          ],
        );
      }

      final xml = await repo.obtenerXmlFirmado(documentoId);
      if (xml == null || xml.trim().isEmpty) {
        return const EnviarEcfeResultado(
          ok: false,
          errores: ['No hay XML firmado. Firma el documento primero.'],
        );
      }

      final gw = DgiiRecepcionGatewayImpl(
        ambiente: cfg.ambiente,
        rutaCertificado: cfg.rutaCertificado,
        claveCertificado: cfg.claveCertificado,
        rncEmisor: cfg.rncEmisor,
      );
      final rnc = cfg.rncEmisor.replaceAll(RegExp(r'\D'), '');
      final encf = doc.encf ?? 'ENCF';
      final nombre = '$rnc$encf.xml';
      final res = await gw.enviarConNombre(
        xml,
        nombre,
        rfce: xml.contains('<RFCE'),
      );
      // Una respuesta satisfactoria todavía no es segura hasta persistirla
      // localmente. Si el guardado falla, se bloqueará el reenvío.
      resultadoRecepcionIncierto =
          res.resultadoIncierto ||
          res.ok ||
          (res.trackId != null && res.trackId!.trim().isNotEmpty);

      final esRfce = xml.contains('<RFCE');
      if (esRfce && res.ok) {
        final estadoFinal = res.estadoDgii == 'aceptado condicional'
            ? EstadoEcfInterno.aceptadoObservacion
            : EstadoEcfInterno.aceptado;

        await repo.actualizarEstado(
          id: documentoId,
          estado: estadoFinal,
          ultimoError: null,
          codigoRespuesta: res.codigo,
          mensajeDgii: res.mensaje,
        );
        return EnviarEcfeResultado(ok: true, trackId: res.trackId);
      }
      if (!res.ok || (!esRfce && (res.trackId ?? '').isEmpty)) {
        final errorGuardado = res.resultadoIncierto
            ? '$marcaEnvioIncierto ${res.mensaje ?? 'Resultado de recepción desconocido'}'
            : res.mensaje;
        final estadoFallido = esRfce && res.estadoDgii == 'rechazado'
            ? EstadoEcfInterno.rechazado
            : EstadoEcfInterno.errorTecnico;

        await repo.actualizarEstado(
          id: documentoId,
          estado: estadoFallido,
          ultimoError: errorGuardado,
          codigoRespuesta: res.codigo,
          mensajeDgii: res.mensaje,
        );
        await repo.registrarEvento(
          documentoId: documentoId,
          paso: 'enviar_recepcion',
          ok: false,
          detalle: res.mensaje,
        );
        return EnviarEcfeResultado(
          ok: false,
          errores: [res.mensaje ?? 'Envío fallido'],
        );
      }

      await repo.actualizarEstado(
        id: documentoId,
        estado: EstadoEcfInterno.enviado,
        trackId: res.trackId,
        codigoRespuesta: res.codigo,
        mensajeDgii: res.mensaje,
        ultimoError: null,
      );
      await repo.registrarEvento(
        documentoId: documentoId,
        paso: 'enviar_recepcion',
        ok: true,
        detalle: 'TrackId ${res.trackId}',
      );
      return EnviarEcfeResultado(ok: true, trackId: res.trackId);
    } catch (e) {
      try {
        await repo.actualizarEstado(
          id: documentoId,
          estado: EstadoEcfInterno.errorTecnico,
          ultimoError: resultadoRecepcionIncierto
              ? '$marcaEnvioIncierto $e'
              : '$e',
        );
        await repo.registrarEvento(
          documentoId: documentoId,
          paso: 'enviar_recepcion',
          ok: false,
          detalle: '$e',
        );
      } catch (_) {}
      return EnviarEcfeResultado(ok: false, errores: ['$e']);
    }
  }
}
