import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:fiscogest_rd/features/gastronomia/domain/entities/gastronomia_entities.dart';

/// Comprobante de venta rápida gastronómica (ticket térmico 80mm).
class ComprobanteRapidoPdf {
  static const double _ancho = 80 * PdfPageFormat.mm;
  static const double _margen = 4 * PdfPageFormat.mm;

  /// Genera el PDF y lo comparte (o imprime si el dispositivo lo permite).
  static Future<void> compartir({
    required int ventaId,
    required List<LineaCarritoGastro> lineas,
    required double subtotal,
    required double descuento,
    required double itbis,
    double propina = 0,
    required double total,
    required String formaPago,
    String nombreNegocio = 'FISCOGEST RD',
    String cliente = 'Consumidor Final',
  }) async {
    final bytes = await generar(
      ventaId: ventaId,
      lineas: lineas,
      subtotal: subtotal,
      descuento: descuento,
      itbis: itbis,
      propina: propina,
      total: total,
      formaPago: formaPago,
      nombreNegocio: nombreNegocio,
      cliente: cliente,
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/ticket_gastro_$ventaId.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Comprobante de venta #$ventaId',
    );
  }

  /// Solo genera los bytes del PDF (útil si quieres imprimir directamente).
  static Future<Uint8List> generar({
    required int ventaId,
    required List<LineaCarritoGastro> lineas,
    required double subtotal,
    required double descuento,
    required double itbis,
    double propina = 0,
    required double total,
    required String formaPago,
    String nombreNegocio = 'FISCOGEST RD',
    String cliente = 'Consumidor Final',
  }) async {
    final doc = pw.Document();
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final fmt = NumberFormat('#,##0.00', 'es_DO');

    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          _ancho,
          double.infinity,
          marginAll: _margen,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Encabezado
              pw.Center(
                child: pw.Text(
                  nombreNegocio.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  'Venta Rápida',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.6),
              pw.SizedBox(height: 3),

              // Datos de la venta
              _fila('Venta #', '$ventaId'),
              _fila('Fecha', fecha),
              _fila('Cliente', cliente),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),

              // Encabezado de columnas
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Text('Descripción',
                        style: pw.TextStyle(
                            fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Cant',
                        style: pw.TextStyle(
                            fontSize: 8, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text('Total',
                        style: pw.TextStyle(
                            fontSize: 8, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              pw.SizedBox(height: 3),
              pw.Divider(thickness: 0.4),

              // Líneas de productos
              ...lineas.map((l) {
                final extrasTexto = l.extras.isNotEmpty
                    ? ' (+${l.extras.map((e) => e.nombre).join(', ')})'
                    : '';
                final notasTexto =
                    l.notas.trim().isNotEmpty ? '\n  Nota: ${l.notas}' : '';

                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            flex: 5,
                            child: pw.Text(
                              '${l.nombre}$extrasTexto$notasTexto',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              l.cantidad % 1 == 0
                                  ? l.cantidad.toInt().toString()
                                  : l.cantidad.toStringAsFixed(2),
                              style: const pw.TextStyle(fontSize: 8),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              'RD\$ ${fmt.format(l.subtotal)}',
                              style: const pw.TextStyle(fontSize: 8),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.6),
              pw.SizedBox(height: 4),

              // Totales
              _totalFila('Subtotal', subtotal, fmt),
              if (descuento > 0)
                _totalFila('Descuento', -descuento, fmt),
              _totalFila('ITBIS 18%', itbis, fmt),
              if (propina > 0)
                _totalFila('Propina', propina, fmt),
              pw.SizedBox(height: 2),
              pw.Divider(thickness: 0.8),
              pw.SizedBox(height: 3),
              _totalFila('TOTAL', total, fmt, negrita: true, grande: true),
              pw.SizedBox(height: 6),

              // Forma de pago
              pw.Center(
                child: pw.Text(
                  'Pago: ${_etiquetaFormaPago(formaPago)}',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  '¡Gracias por su compra!',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  'FiscoGest RD · Gastronomía',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _fila(String label, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(valor, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  static pw.Widget _totalFila(
    String label,
    double valor,
    NumberFormat fmt, {
    bool negrita = false,
    bool grande = false,
  }) {
    final style = pw.TextStyle(
      fontSize: grande ? 10 : 8.5,
      fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text('RD\$ ${fmt.format(valor)}', style: style),
        ],
      ),
    );
  }

  static String _etiquetaFormaPago(String fp) {
    switch (fp.toLowerCase()) {
      case 'efectivo':
        return 'Efectivo';
      case 'tarjeta':
        return 'Tarjeta';
      case 'transferencia':
        return 'Transferencia';
      case 'mixto':
        return 'Mixto';
      default:
        return fp;
    }
  }
}
