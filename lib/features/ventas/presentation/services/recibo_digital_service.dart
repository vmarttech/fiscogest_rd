import 'package:share_plus/share_plus.dart';
import 'package:fiscogest_rd/core/print/recibo_digital_format.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';

/// Servicio comercial para compartir el recibo digital (texto liviano).
class ReciboDigitalService {
  const ReciboDigitalService();

  /// Genera y comparte el recibo digital por el share sheet del sistema.
  Future<void> compartir({
    required Venta venta,
    required ConfiguracionEntity? empresa,
    String? mensajeCierre,
  }) async {
    final texto = generarReciboDigital(
      venta: venta,
      empresa: empresa,
      mensajeCierre: mensajeCierre ?? '¡Dios bendiga tu día! Vuélvenos a visitar.',
    );

    final numero = (venta.numeroFactura?.trim().isNotEmpty == true)
        ? venta.numeroFactura!.trim()
        : venta.numeroCotizacion;

    await Share.share(
      texto,
      subject: 'Recibo #$numero',
    );
  }
}
