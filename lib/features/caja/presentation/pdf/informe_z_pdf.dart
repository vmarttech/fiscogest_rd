import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fiscogest_rd/features/caja/domain/repositories/i_caja_repository.dart';

/// Informe Z de cierre de turno — ticket térmico 80mm.
class InformeZPdf {
  InformeZPdf._();

  static const PdfPageFormat ticket80 = PdfPageFormat(
    80 * PdfPageFormat.mm,
    double.infinity,
    marginAll: 3.5 * PdfPageFormat.mm,
  );

  static String _rd(double v) {
    final neg = v < 0;
    final a = v.abs().toStringAsFixed(2);
    final parts = a.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '${neg ? '-' : ''}RD\$ $intPart.${parts[1]}';
  }

  static String _fecha(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.day)}/${p(d.month)}/${d.year} ${p(d.hour)}:${p(d.minute)}';
  }

  static Future<Uint8List> generar({
    required ResumenSesionCaja resumen,
    required double montoContado,
    String? observacion,
    required DateTime cerradoEn,
    DateTime? fechaApertura,
    String? nombreComercio,
    String? rnc,
    String? telefono,
    String? direccion,
  }) async {
    final dif = montoContado - resumen.efectivoEsperado;
    final doc = pw.Document();
    final nombre = (nombreComercio ?? 'NEGOCIO').trim().toUpperCase();

    pw.Widget line() =>
        pw.Divider(thickness: 0.8, color: PdfColors.grey800);

    pw.Widget row(String a, String b, {bool bold = false}) {
      final style = pw.TextStyle(
        fontSize: 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      );
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(child: pw.Text(a, style: style)),
            pw.Text(b, style: style),
          ],
        ),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: ticket80,
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                nombre,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if ((rnc ?? '').trim().isNotEmpty)
                pw.Text(
                  'RNC: ${rnc!.trim()}',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey700,
                  ),
                ),
              if ((telefono ?? '').trim().isNotEmpty)
                pw.Text(
                  'Tel: ${telefono!.trim()}',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey700,
                  ),
                ),
              if ((direccion ?? '').trim().isNotEmpty)
                pw.Text(
                  direccion!.trim(),
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey700,
                  ),
                ),
              pw.SizedBox(height: 4),
              line(),
              pw.Text(
                'INFORME Z · CIERRE DE TURNO',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              row('Sesión', '#${resumen.sesionId}'),
              if (fechaApertura != null)
                row('Apertura', _fecha(fechaApertura)),
              row('Cierre', _fecha(cerradoEn)),
              line(),
              row('Fondo inicial', _rd(resumen.fondoInicial)),
              row('Ingresos efectivo', _rd(resumen.ingresosEfectivo)),
              row('Ingresos tarjeta', _rd(resumen.ingresosTarjeta)),
              row('Ingresos transfer.', _rd(resumen.ingresosTransferencia)),
              row('Ingresos cheque', _rd(resumen.ingresosCheque)),
              row('Ingresos crédito', _rd(resumen.ingresosCredito)),
              row('Egresos efectivo', _rd(resumen.egresosEfectivo)),
              row('Total ingresos', _rd(resumen.totalIngresos)),
              row('Total egresos', _rd(resumen.totalEgresos)),
              line(),
              row(
                'Efectivo esperado',
                _rd(resumen.efectivoEsperado),
                bold: true,
              ),
              row('Efectivo contado', _rd(montoContado), bold: true),
              row(
                dif.abs() < 0.005
                    ? 'Cuadre'
                    : (dif > 0 ? 'Sobrante' : 'Faltante'),
                _rd(dif.abs()),
                bold: true,
              ),
              if ((observacion ?? '').trim().isNotEmpty) ...[
                line(),
                pw.Text(
                  'Obs: ${observacion!.trim()}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
              line(),
              pw.Text(
                'Fin del Informe Z',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                'Conserve este comprobante',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static Future<void> imprimir({
    required ResumenSesionCaja resumen,
    required double montoContado,
    String? observacion,
    required DateTime cerradoEn,
    DateTime? fechaApertura,
    String? nombreComercio,
    String? rnc,
    String? telefono,
    String? direccion,
    bool compartir = false,
  }) async {
    final bytes = await generar(
      resumen: resumen,
      montoContado: montoContado,
      observacion: observacion,
      cerradoEn: cerradoEn,
      fechaApertura: fechaApertura,
      nombreComercio: nombreComercio,
      rnc: rnc,
      telefono: telefono,
      direccion: direccion,
    );
    final name = 'informe_z_${resumen.sesionId}.pdf';
    if (compartir) {
      await Printing.sharePdf(bytes: bytes, filename: name);
    } else {
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Informe Z #${resumen.sesionId}',
        format: ticket80,
      );
    }
  }
}
