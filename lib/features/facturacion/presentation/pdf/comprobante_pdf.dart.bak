import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Impresión fiscal. Preferir [FacturaImprimible] si el flujo de Ventas ya la usa.
class ComprobantePdf {
  static final _money = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$');
  static final _fecha = DateFormat('dd/MM/yyyy HH:mm');

  static Future<void> imprimirFactura(Venta v) async {
    final ncf = (v.numeroFactura ?? '').trim();
    if (ncf.isEmpty) {
      throw StateError('Sin NCF: no se puede imprimir comprobante fiscal');
    }
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'COMPROBANTE FISCAL',
                style: const pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text('NCF: $ncf'),
              pw.Text('Cotización: ${v.numeroCotizacion}'),
              pw.Text(
                'Cliente: ${v.nombreCliente ?? 'Cliente #${v.clienteId}'}',
              ),
              pw.Text('Fecha: ${_fecha.format(v.fechaRegistro)}'),
              pw.SizedBox(height: 12),
              pw.Text(
                'TOTAL: ${_money.format(v.montoTotal)}',
                style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  static Future<void> imprimirNc({
    required String ncfNc,
    required String ncfOrigen,
    required String cliente,
    required double monto,
    required String motivo,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'NOTA DE CRÉDITO',
                style: const pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text('NCF NC: $ncfNc'),
              pw.Text('Factura origen: $ncfOrigen'),
              pw.Text('Cliente: $cliente'),
              pw.Text('Monto: ${_money.format(monto)}'),
              pw.SizedBox(height: 8),
              pw.Text('Motivo: $motivo'),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }
}
