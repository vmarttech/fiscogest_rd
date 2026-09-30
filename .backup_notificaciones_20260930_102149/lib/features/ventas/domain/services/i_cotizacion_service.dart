import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

abstract class ICotizacionService {
  Future<String> generarImpresion(Venta cotizacion);
  Future<String> exportarPDF(Venta cotizacion);
  Future<void> enviarPorCorreo(Venta cotizacion, String correoDestinatario);
}
