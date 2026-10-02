import 'package:fiscogest_rd/features/e_cf/domain/enums/ambiente_dgii.dart';

/// Configuración del módulo. Si [habilitado] es false, no hay envíos ni encolado automático.
class EcfeConfig {
  const EcfeConfig({
    this.id,
    this.habilitado = false,
    this.ambiente = AmbienteDgii.deshabilitado,
    this.rncEmisor = '',
    this.razonSocialEmisor = '',
    this.rutaCertificado = '',
    this.aliasCertificado = '',
    this.claveCertificado = '',
    this.xsdVersion = '',
  });

  final int? id;
  final bool habilitado;
  final AmbienteDgii ambiente;
  final String rncEmisor;
  final String razonSocialEmisor;
  final String rutaCertificado;
  final String aliasCertificado;
  /// Password del .p12/.pfx. No debe loguearse.
  final String claveCertificado;
  final String xsdVersion;

  bool get listoParaPipeline =>
      habilitado && ambiente.permiteEnvio && rncEmisor.trim().length >= 9;

  bool get tieneCertificado =>
      rutaCertificado.trim().isNotEmpty && claveCertificado.isNotEmpty;
}
