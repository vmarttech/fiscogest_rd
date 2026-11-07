import 'package:fiscogest_rd/features/e_cf/data/gateways/dgii_consulta_gateway_impl.dart';
import 'package:fiscogest_rd/features/e_cf/application/consultar_ecfe.dart';
import 'package:fiscogest_rd/features/e_cf/data/repositories/ecfe_repository.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/estado_ecf_interno.dart';

class ConsultarEstadoEcfeResultado {
  const ConsultarEstadoEcfeResultado({
    required this.ok,
    this.estadoInterno,
    this.estadoDgii,
    this.mensaje,
    this.errores = const [],
  });
  final bool ok;
  final EstadoEcfInterno? estadoInterno;
  final String? estadoDgii;
  final String? mensaje;
  final List<String> errores;
}

class ConsultarEstadoEcfe {
  ConsultarEstadoEcfe({required this.repo});
  final EcfeRepository repo;

  static EstadoEcfInterno? mapearEstadoDgii(String? estado, [String? codigo]) {
    return ConsultarEcfe.mapearEstadoDgii(estado, codigo);
  }

  Future<ConsultarEstadoEcfeResultado> call({required int documentoId}) async {
    try {
      final cfg = await repo.obtenerConfig();
      if (!cfg.listoParaPipeline || !cfg.tieneCertificado) {
        return const ConsultarEstadoEcfeResultado(
          ok: false,
          errores: ['Config e-CF incompleta'],
        );
      }
      final doc = await repo.obtenerPorId(documentoId);
      if (doc == null) {
        return const ConsultarEstadoEcfeResultado(
          ok: false,
          errores: ['Documento no encontrado'],
        );
      }
      final track = doc.trackId;
      if (track == null || track.isEmpty) {
        return const ConsultarEstadoEcfeResultado(
          ok: false,
          errores: ['Sin TrackId: envía el comprobante primero'],
        );
      }

      final gw = DgiiConsultaGatewayImpl(
        ambiente: cfg.ambiente,
        rutaCertificado: cfg.rutaCertificado,
        claveCertificado: cfg.claveCertificado,
      );
      final res = await gw.consultar(track);
      if (!res.ok) {
        await repo.registrarEvento(
          documentoId: documentoId,
          paso: 'consultar_resultado',
          ok: false,
          detalle: res.mensaje,
        );
        return ConsultarEstadoEcfeResultado(
          ok: false,
          errores: [res.mensaje ?? 'Consulta fallida'],
        );
      }

      final interno = mapearEstadoDgii(res.estadoDgii, res.codigo);
      // Una respuesta desconocida no debe modificar el estado persistido.
      if (interno == null) {
        final detalle =
            (res.estadoDgii == null || res.estadoDgii!.trim().isEmpty)
            ? 'DGII no devolvió un estado fiscal reconocible'
            : 'Estado DGII no reconocido: ${res.estadoDgii}';

        await repo.registrarEvento(
          documentoId: documentoId,
          paso: 'consultar_resultado',
          ok: false,
          detalle: detalle,
        );

        return ConsultarEstadoEcfeResultado(
          ok: false,
          estadoInterno: doc.estado,
          estadoDgii: res.estadoDgii,
          mensaje: res.mensaje,
          errores: [detalle],
        );
      }

      // Una respuesta transitoria no puede degradar un estado definitivo.
      final estadoDefinitivo =
          doc.estado == EstadoEcfInterno.aceptado ||
          doc.estado == EstadoEcfInterno.aceptadoObservacion ||
          doc.estado == EstadoEcfInterno.rechazado;

      final estadoAguardar =
          estadoDefinitivo && interno == EstadoEcfInterno.enProceso
          ? doc.estado
          : interno;

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
        estado: estadoAguardar,
        trackId: track,
        codigoRespuesta: res.codigo,
        mensajeDgii: res.mensaje ?? res.estadoDgii,
        ultimoError: conservaIncertidumbre
            ? errorAnterior
            : estadoAguardar == EstadoEcfInterno.rechazado
            ? (interno == EstadoEcfInterno.rechazado
                  ? (res.mensaje ?? res.estadoDgii)
                  : errorAnterior)
            : null,
      );
      await repo.registrarEvento(
        documentoId: documentoId,
        paso: 'consultar_resultado',
        ok: true,
        detalle: '${res.estadoDgii ?? interno.etiqueta} · ${res.mensaje ?? ''}',
      );

      return ConsultarEstadoEcfeResultado(
        ok: true,
        estadoInterno: estadoAguardar,
        estadoDgii: res.estadoDgii,
        mensaje: res.mensaje,
      );
    } catch (e) {
      return ConsultarEstadoEcfeResultado(ok: false, errores: ['$e']);
    }
  }
}
