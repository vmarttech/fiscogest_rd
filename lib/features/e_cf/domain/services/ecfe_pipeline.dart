import 'package:fiscogest_rd/features/e_cf/domain/entities/ecfe_documento.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/estado_ecf_interno.dart';
import 'package:fiscogest_rd/features/e_cf/domain/ports/dgii_consulta_gateway.dart';
import 'package:fiscogest_rd/features/e_cf/domain/ports/dgii_recepcion_gateway.dart';
import 'package:fiscogest_rd/features/e_cf/domain/ports/ecfe_signer.dart';
import 'package:fiscogest_rd/features/e_cf/domain/ports/ecfe_xml_builder.dart';
import 'package:fiscogest_rd/features/e_cf/domain/ports/ecfe_xsd_validator.dart';

/// Orquesta el pipeline. No toca ventas ni caja.
/// En Fase 0 las implementaciones de puertos son no-op / rechazo controlado.
class EcfePipeline {
  EcfePipeline({
    required this.xmlBuilder,
    required this.xsdValidator,
    required this.signer,
    required this.recepcion,
    required this.consulta,
  });

  final EcfeXmlBuilder xmlBuilder;
  final EcfeXsdValidator xsdValidator;
  final EcfeSigner signer;
  final DgiiRecepcionGateway recepcion;
  final DgiiConsultaGateway consulta;

  /// Avanza un documento un paso seguro. Nunca lanza hacia UI de ventas.
  Future<EcfeDocumento> avanzar(
    EcfeDocumento doc, {
    Map<String, dynamic> payloadNegocio = const {},
  }) async {
    switch (doc.estado) {
      case EstadoEcfInterno.borrador:
      case EstadoEcfInterno.validacionFallida:
        // Fase 1: validador de negocio real
        return _copy(doc, estado: EstadoEcfInterno.xmlListo);

      case EstadoEcfInterno.xmlListo:
        final xml = await xmlBuilder.construir(doc, payloadNegocio);
        final xsd = await xsdValidator.validar(xml);
        if (!xsd.ok) {
          return _copy(
            doc,
            estado: EstadoEcfInterno.validacionFallida,
            ultimoError: xsd.errores.join('; '),
          );
        }
        await signer.firmar(xml);
        return _copy(doc, estado: EstadoEcfInterno.firmado, ultimoError: null);

      case EstadoEcfInterno.firmado:
        final envio = await recepcion.enviar(''); // XML firmado en fases posteriores
        if (!envio.ok || (envio.trackId ?? '').isEmpty) {
          return _copy(
            doc,
            estado: EstadoEcfInterno.errorTecnico,
            ultimoError: envio.mensaje ?? 'Envío no disponible (módulo en preparación)',
          );
        }
        return _copy(
          doc,
          estado: EstadoEcfInterno.enviado,
          trackId: envio.trackId,
        );

      case EstadoEcfInterno.enviado:
      case EstadoEcfInterno.enProceso:
        final track = doc.trackId;
        if (track == null || track.isEmpty) {
          return _copy(
            doc,
            estado: EstadoEcfInterno.errorTecnico,
            ultimoError: 'Sin TrackId',
          );
        }
        final r = await consulta.consultar(track);
        if (!r.ok) {
          return _copy(
            doc,
            estado: EstadoEcfInterno.enProceso,
            mensajeDgii: r.mensaje,
          );
        }
        // Mapeo fino de estados DGII en fases posteriores
        return _copy(
          doc,
          estado: EstadoEcfInterno.enProceso,
          codigoRespuesta: r.codigo,
          mensajeDgii: r.mensaje,
        );

      default:
        return doc;
    }
  }

  EcfeDocumento _copy(
    EcfeDocumento d, {
    EstadoEcfInterno? estado,
    String? trackId,
    String? codigoRespuesta,
    String? mensajeDgii,
    String? ultimoError,
  }) {
    return EcfeDocumento(
      id: d.id,
      ventaId: d.ventaId,
      tipoEcf: d.tipoEcf,
      encf: d.encf,
      estado: estado ?? d.estado,
      trackId: trackId ?? d.trackId,
      codigoRespuesta: codigoRespuesta ?? d.codigoRespuesta,
      mensajeDgii: mensajeDgii ?? d.mensajeDgii,
      ultimoError: ultimoError,
      creadoEn: d.creadoEn,
      actualizadoEn: DateTime.now(),
    );
  }
}
