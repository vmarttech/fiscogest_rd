import 'package:fiscogest_rd/features/e_cf/domain/entities/ecfe_documento.dart';

/// Construye XML e-CF según XSD vigente. Sin red.
abstract class EcfeXmlBuilder {
  Future<String> construir(EcfeDocumento doc, Map<String, dynamic> payloadNegocio);
}
