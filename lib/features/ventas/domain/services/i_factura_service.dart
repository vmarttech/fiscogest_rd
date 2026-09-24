import 'dart:typed_data';

import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

abstract class IFacturaService {
  /// Texto del ticket (portapapeles / respaldo).
  String generarTextoFactura(Venta venta);

  /// Bytes del PDF real.
  Future<Uint8List> generarPdfBytes(Venta venta);

  /// Copia el ticket al portapapeles.
  Future<void> imprimirFactura(Venta venta);

  /// Abre el diálogo nativo de impresión con el PDF.
  Future<void> imprimirPdf(Venta venta);

  /// Guarda el PDF en temporal y devuelve la ruta.
  Future<String> exportarPDF(Venta venta);

  /// Comparte el PDF (correo / WhatsApp / etc.).
  Future<void> enviarPorCorreo(Venta venta, String correoDestinatario);
}
