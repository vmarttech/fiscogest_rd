import 'package:fiscogest_rd/features/e_cf/domain/services/codigo_seguridad_ecf.dart';
import 'package:fiscogest_rd/features/e_cf/data/repositories/ecfe_repository.dart';
import 'package:fiscogest_rd/features/e_cf/data/xml/ecfe_signer_impl.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/estado_ecf_interno.dart';
import 'package:fiscogest_rd/features/e_cf/domain/ports/ecfe_signer.dart';
import 'package:fiscogest_rd/features/e_cf/data/xml/rfce_xml.dart';

class FirmarXmlResultado {
  const FirmarXmlResultado({
    required this.ok,
    this.xmlFirmado,
    this.errores = const [],
  });
  final bool ok;
  final String? xmlFirmado;
  final List<String> errores;
}

class FirmarXmlEcfe {
  FirmarXmlEcfe({required this.repo});

  final EcfeRepository repo;

  Future<FirmarXmlResultado> call({required int documentoId}) async {
    try {
      final doc = await repo.obtenerPorId(documentoId);
      if (doc == null) {
        return const FirmarXmlResultado(
          ok: false,
          errores: ['Documento no encontrado'],
        );
      }
      if (doc.estado != EstadoEcfInterno.xmlListo &&
          doc.estado != EstadoEcfInterno.firmado &&
          doc.estado != EstadoEcfInterno.errorTecnico) {
        return FirmarXmlResultado(
          ok: false,
          errores: [
            'Estado ${doc.estado.etiqueta}: se requiere XML listo para firmar',
          ],
        );
      }

      final xml = await repo.obtenerXmlSinFirma(documentoId);
      if (xml == null || xml.trim().isEmpty) {
        return const FirmarXmlResultado(
          ok: false,
          errores: ['No hay XML sin firma guardado. Genera el XML primero.'],
        );
      }

      final cfg = await repo.obtenerConfig();
      final EcfeSigner signer = (cfg.rutaCertificado.trim().isEmpty)
          ? NoOpEcfeSigner()
          : EcfeSignerImpl(
              rutaCertificado: cfg.rutaCertificado,
              claveCertificado: cfg.claveCertificado,
            );

      final firmadoCompleto = await signer.firmar(xml);
      final codigoSeg = CodigoSeguridadEcf.empaquetar(
        CodigoSeguridadEcf.desdeXmlFirmado(firmadoCompleto),
        CodigoSeguridadEcf.fechaDeXml(firmadoCompleto),
      );
      final firmado = RfceXml.esResumenConsumo(firmadoCompleto)
          ? await signer.firmar(
              RfceXml.desdeEcfFirmado(
                firmadoCompleto,
                CodigoSeguridadEcf.soloCodigo(codigoSeg),
              ),
            )
          : firmadoCompleto;

      await repo.guardarXmlFirmado(
        id: documentoId,
        xmlFirmado: firmado,
        estado: EstadoEcfInterno.firmado,
        codigoSeguridad: codigoSeg,
        ultimoError: null,
      );
      await repo.registrarEvento(
        documentoId: documentoId,
        paso: 'firmar',
        ok: true,
        detalle: 'XML firmado (XMLDSig RSA-SHA256)',
      );

      return FirmarXmlResultado(ok: true, xmlFirmado: firmado);
    } catch (e) {
      try {
        await repo.actualizarEstado(
          id: documentoId,
          estado: EstadoEcfInterno.errorTecnico,
          ultimoError: '$e',
        );
        await repo.registrarEvento(
          documentoId: documentoId,
          paso: 'firmar',
          ok: false,
          detalle: '$e',
        );
      } catch (_) {}
      return FirmarXmlResultado(ok: false, errores: ['$e']);
    }
  }
}
