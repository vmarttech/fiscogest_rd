import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

/// Ticket térmico 80mm: abono inicial de venta a crédito (NO fiscal).
/// Complementa la factura normal; sirve de respaldo para cuadre de caja.
class ComprobanteAbonoInicialPdf {
  ComprobanteAbonoInicialPdf._();

  static const PdfPageFormat ticket80 = PdfPageFormat(
    80 * PdfPageFormat.mm,
    double.infinity,
    marginAll: 3.5 * PdfPageFormat.mm,
  );

  static Future<Uint8List> generar({
    required Venta venta,
    required double montoAbono,
    required String metodoPago,
    required DateTime fecha,
    ConfiguracionEntity? empresa,
    String? cajero,
    String? cajaTurno,
    double? recibido,
    double? cambio,
  }) async {
    final doc = pw.Document();
    final empNombre = _nombreEmpresa(empresa);
    final empRnc = (empresa?.rnc ?? '').trim();
    final empTel = (empresa?.telefono ?? '').trim();
    final empDir = (empresa?.direccion ?? '').trim();
    final nombreCli = (venta.nombreCliente ?? '').trim();
    final cliente = nombreCli.isEmpty
        ? 'CONSUMIDOR FINAL'
        : nombreCli.toUpperCase();
    final nFactura =
        (venta.numeroFactura ?? venta.numeroCotizacion).trim();
    final nCotiz = venta.numeroCotizacion.trim();
    final totalDoc = venta.montoTotal;
    final saldo = (totalDoc - montoAbono).clamp(0.0, double.infinity);
    final fechaStr =
        '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year} '
        '${fecha.hour.toString().padLeft(2, '0')}:'
        '${fecha.minute.toString().padLeft(2, '0')}';
    final refCaja =
        'ABI-${fecha.millisecondsSinceEpoch.toString().substring(7)}';

    doc.addPage(
      pw.Page(
        pageFormat: ticket80,
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                empNombre,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                    fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
              if (empRnc.isNotEmpty)
                pw.Text(
                  'RNC: $empRnc',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              if (empTel.isNotEmpty)
                pw.Text(
                  'Tel: $empTel',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 7),
                ),
              if (empDir.isNotEmpty)
                pw.Text(
                  empDir,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 7),
                ),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#ECFDF5'),
                  border: pw.Border.all(
                      color: PdfColor.fromHex('#059669'), width: 1),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'ABONO INICIAL — CRÉDITO',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#047857'),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Documento NO fiscal',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 7,
                        color: PdfColor.fromHex('#065F46'),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              _dash(),
              pw.SizedBox(height: 4),
              _row('Ref. caja:', refCaja),
              _row('Fecha:', fechaStr),
              _row('Factura / NCF:', nFactura),
              if (nCotiz.isNotEmpty && nCotiz != nFactura)
                _row('Cotización:', nCotiz),
              _row('Cliente:', cliente),
              if ((cajero ?? '').trim().isNotEmpty)
                _row('Cajero:', cajero!.trim()),
              if ((cajaTurno ?? '').trim().isNotEmpty)
                _row('Turno caja:', cajaTurno!.trim()),
              pw.SizedBox(height: 4),
              _dash(),
              pw.SizedBox(height: 4),
              pw.Text(
                'DETALLE DEL ABONO',
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 3),
              _row('Total de la venta:', formatRd(totalDoc)),
              _row('Abono inicial:', formatRd(montoAbono), boldValue: true),
              _row('Saldo a financiar:', formatRd(saldo), boldValue: true),
              _row('Método de pago:', metodoPago),
              if (recibido != null) _row('Recibido:', formatRd(recibido)),
              if (cambio != null && cambio >= 0)
                _row('Cambio:', formatRd(cambio)),
              pw.SizedBox(height: 4),
              _dash(),
              pw.SizedBox(height: 4),
              pw.Text(
                'Este ticket registra el efectivo/medios de pago '
                'recibidos como abono inicial. La factura fiscal '
                'con el detalle de productos se imprime por separado. '
                'Conserve ambos para cuadre de caja y CxC.',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(
                    fontSize: 6.5, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                '¡Gracias!',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                    fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  static Future<void> imprimir({
    required Venta venta,
    required double montoAbono,
    required String metodoPago,
    required DateTime fecha,
    ConfiguracionEntity? empresa,
    String? cajero,
    String? cajaTurno,
    double? recibido,
    double? cambio,
    bool compartir = false,
  }) async {
    final bytes = await generar(
      venta: venta,
      montoAbono: montoAbono,
      metodoPago: metodoPago,
      fecha: fecha,
      empresa: empresa,
      cajero: cajero,
      cajaTurno: cajaTurno,
      recibido: recibido,
      cambio: cambio,
    );
    if (compartir) {
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'abono_inicial_${venta.numeroCotizacion}.pdf',
      );
    } else {
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'abono_inicial_${venta.numeroCotizacion}',
        format: ticket80,
      );
    }
  }

  static String _nombreEmpresa(ConfiguracionEntity? e) {
    if (e == null) return 'NEGOCIO';
    final n = e.nombreComercial.trim();
    if (n.isNotEmpty) return n.toUpperCase();
    final r = e.razonSocial.trim();
    return r.isEmpty ? 'NEGOCIO' : r.toUpperCase();
  }

  static pw.Widget _dash() => pw.Text(
        '- - - - - - - - - - - - - - - - - - - -',
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
      );

  static pw.Widget _row(
    String label,
    String value, {
    bool boldValue = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 5,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          ),
          pw.Expanded(
            flex: 6,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight:
                    boldValue ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
