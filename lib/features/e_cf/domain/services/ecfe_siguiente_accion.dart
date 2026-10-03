import 'package:fiscogest_rd/features/e_cf/domain/enums/estado_ecf_interno.dart';

class EcfeSiguienteAccion {
  const EcfeSiguienteAccion._();

  static String etiqueta(EstadoEcfInterno e, {String? trackId}) {
    switch (e) {
      case EstadoEcfInterno.borrador:
      case EstadoEcfInterno.validacionFallida:
        return 'Generar / validar XML';
      case EstadoEcfInterno.xmlListo:
        return 'Firmar XML';
      case EstadoEcfInterno.firmado:
        return 'Enviar a DGII';
      case EstadoEcfInterno.enviado:
      case EstadoEcfInterno.enProceso:
        return (trackId ?? '').isNotEmpty
            ? 'Consultar estado DGII'
            : 'Reintentar envío';
      case EstadoEcfInterno.errorTecnico:
        return (trackId ?? '').isNotEmpty
            ? 'Consultar / revisar error'
            : 'Reintentar (firmar/enviar)';
      case EstadoEcfInterno.rechazado:
        return 'Revisar rechazo DGII';
      case EstadoEcfInterno.aceptado:
      case EstadoEcfInterno.aceptadoObservacion:
        return 'Imprimir RI (QR)';
      case EstadoEcfInterno.anulado:
        return 'Sin acción';
    }
  }
}
