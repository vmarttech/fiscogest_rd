import 'package:fiscogest_rd/features/facturacion/presentation/pdf/comprobante_pdf.dart';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/i_factura_service.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:fiscogest_rd/features/impuestos/domain/services/resolver_tasa_itbis.dart';

class FacturaServiceImpl implements IFacturaService {
  FacturaServiceImpl();

  static final _fmtFecha = DateFormat('dd/MM/yyyy HH:mm');
  String _monto(double v) => formatRd(v);

  @override
  String generarTextoFactura(Venta venta) {
    final b = StringBuffer();
    b.writeln('========================================');
    b.writeln('           FISCOGEST RD');
    b.writeln('         FACTURA DE VENTA');
    b.writeln('========================================');
    b.writeln('');
    if (venta.numeroFactura != null && venta.numeroFactura!.isNotEmpty) {
      b.writeln('N° Factura: ${venta.numeroFactura}');
      b.writeln('Ref. Cotización: ${venta.numeroCotizacion}');
    } else {
      b.writeln('Cotización: ${venta.numeroCotizacion}');
    }
    b.writeln('Fecha:  ${_fmtFecha.format(venta.fecha)}');
    b.writeln('Cliente ID: ${venta.clienteId}');
    if (venta.nombreCliente != null && venta.nombreCliente!.isNotEmpty) {
      b.writeln('Cliente: ${venta.nombreCliente}');
    }
    b.writeln('Forma de Pago: ${venta.tipoPago.toUpperCase()}');
    b.writeln(venta.esCredito ? 'Crédito: SÍ' : 'Crédito: NO');
    if (venta.costoEnvio > 0) {
      b.writeln('Envío: ${_monto(venta.costoEnvio)}');
    }
    if (venta.abonoInicial > 0) {
      b.writeln('Abono: ${_monto(venta.abonoInicial)}');
    }
    b.writeln('');
    b.writeln('----------------------------------------');
    b.writeln('DETALLE DE PRODUCTOS');
    b.writeln('----------------------------------------');
    for (var i = 0; i < venta.detalles.length; i++) {
      final d = venta.detalles[i];
      b.writeln('${i + 1}. ${d.nombreProducto ?? "Producto"}');
      b.writeln('   Cant: ${d.cantidad}  x  ${_monto(d.precioUnitario)}');
      final sub = d.subtotalLinea ?? d.subtotal;
      b.writeln('   Subtotal: ${_monto(sub)}${sufijoTasaLinea(d.tasaImpuesto, ceroEsExento: lineasCeroSonExentas(venta.detalles.map((e) => e.tasaImpuesto), venta.itbis))}');
      b.writeln('');
    }
    b.writeln('----------------------------------------');
    b.writeln('Subtotal:          ${_monto(venta.subtotal)}');
    if (venta.montoDescuento > 0) {
      b.writeln('Descuento:         ${_monto(venta.montoDescuento)}');
    }
    b.writeln('${etiquetaItbisLineas(venta.detalles.map((d) => d.tasaImpuesto))}:       ${_monto(venta.itbis)}');
    if (venta.costoEnvio > 0) {
      b.writeln('Envío:             ${_monto(venta.costoEnvio)}');
    }
    b.writeln('========================================');
    b.writeln('TOTAL A PAGAR:     ${_monto(venta.total)}');
    b.writeln('========================================');
    b.writeln('');
    b.writeln('       ¡GRACIAS POR SU COMPRA!');
    b.writeln('========================================');
    return b.toString();
  }

  @override
  Future<Uint8List> generarPdfBytes(Venta venta) async {
    final doc = pw.Document();
    final nro = venta.numeroFactura ?? venta.numeroCotizacion;

    final filas = <List<String>>[
      for (final d in venta.detalles)
        [
          d.nombreProducto ?? 'Producto',
          d.cantidad.toString(),
          _monto(d.precioUnitario),
          _monto(d.subtotalLinea ?? d.subtotal),
        ],
    ];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'FISCOGEST RD',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'FACTURA DE VENTA',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 8),
          if (venta.numeroFactura != null &&
              venta.numeroFactura!.isNotEmpty) ...[
            _fila('N° Factura', venta.numeroFactura!),
            _fila('Ref. Cotización', venta.numeroCotizacion),
          ] else
            _fila('Cotización', venta.numeroCotizacion),
          _fila('Fecha', _fmtFecha.format(venta.fecha)),
          _fila(
            'Cliente',
            venta.nombreCliente?.isNotEmpty == true
                ? venta.nombreCliente!
                : 'ID ${venta.clienteId}',
          ),
          _fila('Forma de pago', venta.tipoPago.toUpperCase()),
          _fila('Crédito', venta.esCredito ? 'SÍ' : 'NO'),
          if (venta.abonoInicial > 0)
            _fila('Abono inicial', _monto(venta.abonoInicial)),
          pw.SizedBox(height: 16),
          pw.Text(
            'Detalle',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Producto', 'Cant.', 'P. unit.', 'Subtotal'],
            data: filas,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 220,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _tot('Subtotal', _monto(venta.subtotal)),
                  if (venta.montoDescuento > 0)
                    _tot('Descuento', _monto(venta.montoDescuento)),
                  _tot(etiquetaItbisLineas(venta.detalles.map((d) => d.tasaImpuesto)), _monto(venta.itbis)),
                  if (venta.costoEnvio > 0)
                    _tot('Envío', _monto(venta.costoEnvio)),
                  pw.Divider(),
                  _tot('TOTAL', _monto(venta.total), negrita: true),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 32),
          pw.Center(
            child: pw.Text(
              '¡Gracias por su compra!',
              style: pw.TextStyle(
                fontSize: 11,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Documento $nro',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _fila(String k, String v) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              k,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(v, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  pw.Widget _tot(String k, String v, {bool negrita = false}) {
    final style = pw.TextStyle(
      fontSize: negrita ? 12 : 10,
      fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(k, style: style),
          pw.Text(v, style: style),
        ],
      ),
    );
  }

  @override
  Future<void> imprimirFactura(Venta venta) async {
    final texto = generarTextoFactura(venta);
    await Clipboard.setData(ClipboardData(text: texto));
  }

  @override
  Future<void> imprimirPdf(Venta venta) async {
    await ComprobantePdf.imprimirFactura(venta, compartir: false);
  }

  @override
  Future<String> exportarPDF(Venta venta) async {
    final bytes = await ComprobantePdf.generarBytes(venta);
    final directorio = await getTemporaryDirectory();
    final ref = (venta.numeroFactura ?? venta.numeroCotizacion)
        .replaceAll('/', '_')
        .replaceAll(' ', '_');
    final ruta = '${directorio.path}/factura_$ref.pdf';
    await File(ruta).writeAsBytes(bytes, flush: true);
    return ruta;
  }

  @override
  Future<void> enviarPorCorreo(Venta venta, String correoDestinatario) async {
    final ruta = await exportarPDF(venta);
    final nro = venta.numeroFactura ?? venta.numeroCotizacion;
    await Share.shareXFiles(
      [XFile(ruta, mimeType: 'application/pdf')],
      text: correoDestinatario.isNotEmpty
          ? 'Destinatario: $correoDestinatario\nAdjunto factura $nro'
          : 'Adjunto factura $nro',
      subject: 'Factura $nro — FiscoGest RD',
    );
  }
}
