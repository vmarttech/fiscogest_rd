import 'package:fiscogest_rd/features/e_cf/domain/enums/ambiente_dgii.dart';

class DgiiEndpoints {

  const DgiiEndpoints._();
  static bool modoPractica = false;

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

  /// Resumen de factura de consumo, menor de RD$250,000.
  static String apiRecepcionFc(AmbienteDgii a) {
    final url = apiRecepcion(a);
    final conHost = url.contains('ecf.dgii.gov.do')
        ? url.replaceFirst('ecf.dgii.gov.do', 'fc.dgii.gov.do')
        : url;
    final cola = conHost.contains('/Recepcion/')
        ? '/RecepcionFC/api/recepcion/ecf'
        : '/recepcionfc/api/recepcion/ecf';
    return conHost.replaceFirst(
      RegExp(r'/recepcion/api/.*', caseSensitive: false),
      cola,
    );
  }

  static String apiEstadoTrackId(AmbienteDgii a, String trackId) =>
      '${consultaResultado(a)}/api/Consultas/Estado?TrackId=${Uri.encodeQueryComponent(trackId)}';

  static String apiSemilla(AmbienteDgii a) =>
      '${autenticacion(a)}/api/Autenticacion/Semilla';

  static String apiValidarSemilla(AmbienteDgii a) =>
      '${autenticacion(a)}/api/Autenticacion/ValidarSemilla';
}
