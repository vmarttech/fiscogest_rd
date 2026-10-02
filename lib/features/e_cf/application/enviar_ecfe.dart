import 'package:fiscogest_rd/features/e_cf/data/gateways/dgii_recepcion_gateway_impl.dart';
import 'package:fiscogest_rd/features/e_cf/data/repositories/ecfe_repository.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/estado_ecf_interno.dart';

class EnviarEcfeResultado {
  const EnviarEcfeResultado({
    required this.ok,
    this.trackId,
    this.errores = const [],
  });
  final bool ok;
  final String? trackId;
  final List<String> errores;
}

class EnviarEcfe {
  EnviarEcfe({required this.repo});
  final EcfeRepository repo;

  Future<EnviarEcfeResultado> call({required int documentoId}) async {
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
      if (doc.estado != EstadoEcfInterno.firmado &&
          doc.estado != EstadoEcfInterno.errorTecnico &&
          doc.estado != EstadoEcfInterno.enviado) {
        return EnviarEcfeResultado(
          ok: false,
          errores: [
            'Estado ${doc.estado.etiqueta}: se requiere XML firmado para enviar',
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

      final res = await gw.enviarConNombre(xml, nombre);
      if (!res.ok || (res.trackId ?? '').isEmpty) {
        await repo.actualizarEstado(
          id: documentoId,
          estado: EstadoEcfInterno.errorTecnico,
          ultimoError: res.mensaje,
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
          ultimoError: '$e',
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
