import 'package:fiscogest_rd/features/e_cf/domain/entities/ecfe_documento.dart';
import 'package:fiscogest_rd/features/e_cf/domain/ports/dgii_consulta_gateway.dart';
import 'package:fiscogest_rd/features/e_cf/domain/ports/dgii_recepcion_gateway.dart';
import 'package:fiscogest_rd/features/e_cf/domain/ports/ecfe_signer.dart';
import 'package:fiscogest_rd/features/e_cf/domain/ports/ecfe_xml_builder.dart';
import 'package:fiscogest_rd/features/e_cf/domain/ports/ecfe_xsd_validator.dart';

/// Implementaciones seguras: no contactan DGII ni firman.
class StubEcfeXmlBuilder implements EcfeXmlBuilder {
  @override
  Future<String> construir(
    EcfeDocumento doc,
    Map<String, dynamic> payloadNegocio,
  ) async {
    return '<!-- e-CF stub: builder pendiente de XSD DGII vigente -->';
  }
}

class StubEcfeXsdValidator implements EcfeXsdValidator {
  @override
  Future<EcfeXsdResultado> validar(String xml) async {
    if (xml.trim().isEmpty) {
      return const EcfeXsdResultado(ok: false, errores: ['XML vacío']);
    }
    // Fase 0: no valida XSD real
    return const EcfeXsdResultado(ok: true);
  }
}

class StubEcfeSigner implements EcfeSigner {
  @override
  Future<String> firmar(String xmlSinFirma) async {
    return xmlSinFirma; // sin firma real
  }
}

class StubDgiiRecepcionGateway implements DgiiRecepcionGateway {
  @override
  Future<DgiiRecepcionResultado> enviar(String xmlFirmado) async {
    return const DgiiRecepcionResultado(
      ok: false,
      mensaje: 'Recepción DGII no configurada (Fase 0)',
    );
  }
}

class StubDgiiConsultaGateway implements DgiiConsultaGateway {
  @override
  Future<DgiiConsultaResultado> consultar(String trackId) async {
    return const DgiiConsultaResultado(
      ok: false,
      mensaje: 'Consulta DGII no configurada (Fase 0)',
    );
  }
}
