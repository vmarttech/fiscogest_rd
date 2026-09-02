import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/i_cotizacion_service.dart';

class CotizacionServiceImpl implements ICotizacionService {
  CotizacionServiceImpl();

  String _generarTextoCotizacion(Venta cotizacion) {
    final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');
    final formatoMoneda = NumberFormat.currency(
      locale: 'es_DO',
      symbol: 'RD\$ ',
      decimalDigits: 2,
    );
    final texto = StringBuffer();
    texto.writeln('========================================');
    texto.writeln('           FISCOGEST RD');
    texto.writeln('         COTIZACIÓN');
    texto.writeln('========================================');
    texto.writeln('');
    texto.writeln('Número: ${cotizacion.numero}');
    texto.writeln('Fecha:  ${formatoFecha.format(cotizacion.fecha)}');
    texto.writeln('Cliente ID: ${cotizacion.clienteId}');
    if (cotizacion.nombreCliente != null) {
      texto.writeln('Cliente: ${cotizacion.nombreCliente}');
    }
    texto.writeln('Forma de Pago: ${cotizacion.tipoPago.toUpperCase()}');
    texto.writeln(cotizacion.esCredito ? 'Crédito: SÍ' : 'Crédito: NO');
    texto.writeln('');
    texto.writeln('----------------------------------------');
    texto.writeln('DETALLE DE PRODUCTOS');
    texto.writeln('----------------------------------------');
    for (var i = 0; i < cotizacion.detalles.length; i++) {
      final detalle = cotizacion.detalles[i] as DetalleVenta;
      texto.writeln('${i + 1}. ${detalle.nombreProducto ?? "Producto"}');
      texto.writeln(
        '   Cant: ${detalle.cantidad}  x  ${formatoMoneda.format(detalle.precioUnitario)}',
      );
      if (detalle.descuentoPorcentaje > 0) {
        texto.writeln(
          '   Desc: ${detalle.descuentoPorcentaje.toStringAsFixed(2)}%',
        );
      }
      if (detalle.montoDescuento > 0) {
        texto.writeln(
          '   Desc: ${formatoMoneda.format(detalle.montoDescuento)}',
        );
      }
      final subtotalLinea = detalle.subtotalLinea ?? detalle.subtotal;
      texto.writeln('   Subtotal: ${formatoMoneda.format(subtotalLinea)}');
      texto.writeln('');
    }
    texto.writeln('----------------------------------------');
    texto.writeln(
      'Subtotal:          ${formatoMoneda.format(cotizacion.subtotal)}',
    );
    texto.writeln(
      'ITBIS (18%):       ${formatoMoneda.format(cotizacion.itbis)}',
    );
    texto.writeln('========================================');
    texto.writeln(
      'TOTAL COTIZACIÓN:  ${formatoMoneda.format(cotizacion.total)}',
    );
    texto.writeln('========================================');
    texto.writeln('');
    texto.writeln('Usuario ID: ${cotizacion.usuarioId ?? "N/A"}');
    texto.writeln('');
    texto.writeln('       VÁLIDO COMO COTIZACIÓN');
    texto.writeln('========================================');
    return texto.toString();
  }

  @override
  Future<String> generarImpresion(Venta cotizacion) async {
    final texto = _generarTextoCotizacion(cotizacion);
    await Clipboard.setData(ClipboardData(text: texto));
    return 'Texto copiado al portapapeles — listo para imprimir';
  }

  @override
  Future<String> exportarPDF(Venta cotizacion) async {
    final texto = _generarTextoCotizacion(cotizacion);
    final directorio = await getTemporaryDirectory();
    final nombreArchivo =
        'cotizacion_${cotizacion.numero.replaceAll('/', '_')}.txt';
    final rutaArchivo = '${directorio.path}/$nombreArchivo';
    final archivo = File(rutaArchivo);
    await archivo.writeAsString(texto);
    return rutaArchivo;
  }

  @override
  Future<void> enviarPorCorreo(
    Venta cotizacion,
    String correoDestinatario,
  ) async {
    final rutaArchivo = await exportarPDF(cotizacion);
    await Share.shareXFiles(
      [XFile(rutaArchivo)],
      text: 'Adjunto cotización ${cotizacion.numero}',
      subject: 'Cotización ${cotizacion.numero} — FiscoGest RD',
    );
  }
}
