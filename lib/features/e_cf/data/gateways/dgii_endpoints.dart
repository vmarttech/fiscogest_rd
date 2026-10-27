import 'package:fiscogest_rd/features/e_cf/domain/enums/ambiente_dgii.dart';

class DgiiEndpoints {

  const DgiiEndpoints._();

  static String baseEcf(AmbienteDgii a) {
    switch (a) {
      case AmbienteDgii.precertificacion:
        return 'https://ecf.dgii.gov.do/testecf';
      case AmbienteDgii.certificacion:
        return 'https://ecf.dgii.gov.do/certecf';
      case AmbienteDgii.produccion:
        return 'https://ecf.dgii.gov.do/ecf';
      case AmbienteDgii.deshabilitado:
        return '';
    }
  }

  static String autenticacion(AmbienteDgii a) => '${baseEcf(a)}/autenticacion';
  static String recepcion(AmbienteDgii a) => '${baseEcf(a)}/recepcion';
  static String consultaResultado(AmbienteDgii a) =>
      '${baseEcf(a)}/consultaresultado';

  static String apiRecepcion(AmbienteDgii a) =>
      '${recepcion(a)}/api/facturaselectronicas';

  /// Resumen Factura de Consumo (RFCE) < RD\$250,000.
  /// URLs oficiales DGII (host fc.dgii.gov.do, servicio recepcionfc).
  static String apiRecepcionFc(AmbienteDgii a) {
    switch (a) {
      case AmbienteDgii.precertificacion:
        return 'https://fc.dgii.gov.do/testecf/recepcionfc/api/recepcion/ecf';
      case AmbienteDgii.certificacion:
        return 'https://fc.dgii.gov.do/certecf/recepcionfc/api/recepcion/ecf';
      case AmbienteDgii.produccion:
        return 'https://fc.dgii.gov.do/ecf/recepcionfc/api/recepcion/ecf';
      case AmbienteDgii.deshabilitado:
        return '';
    }
  }

  static String apiEstadoTrackId(AmbienteDgii a, String trackId) =>
      '${consultaResultado(a)}/api/Consultas/Estado?TrackId=${Uri.encodeQueryComponent(trackId)}';

  static String apiSemilla(AmbienteDgii a) =>
      '${autenticacion(a)}/api/Autenticacion/Semilla';

  static String apiValidarSemilla(AmbienteDgii a) =>
      '${autenticacion(a)}/api/Autenticacion/ValidarSemilla';
}
