import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fiscogest_rd/features/nomina/domain/entities/planilla.dart';
import 'package:fiscogest_rd/features/nomina/domain/services/calculadora_nomina_rd.dart';

/// Comprobante de pago individual (recibo de nómina por empleado).
class ComprobanteEmpleadoPdf {
  ComprobanteEmpleadoPdf._();

  static String _rd(double v) {
    final neg = v < 0;
    final cents = (v.abs() * 100).round();
    final entero = cents ~/ 100;
    final dec = (cents % 100).toString().padLeft(2, '0');
    final s = entero.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '${neg ? '-' : ''}RD\$$s.$dec';
  }

  static String _fecha(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.day)}/${p(d.month)}/${d.year}';
  }

  static pw.Widget _row(String a, String b, {bool bold = false, double size = 10}) {
    final style = pw.TextStyle(
      fontSize: size,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(child: pw.Text(a, style: style)),
          pw.Text(b, style: style),
        ],
      ),
    );
  }

  static Future<Uint8List> generar({
    required Planilla planilla,
    required PlanillaLinea linea,
    String? nombreComercio,
    String? rnc,
  }) async {
    final doc = pw.Document();
    final comercio =
        (nombreComercio != null && nombreComercio.trim().isNotEmpty)
            ? nombreComercio.trim()
            : 'FiscoGest';
    final descuentos = linea.tssAfp + linea.tssSfs + linea.isr;
    final patronal = linea.totalPatronal;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                comercio,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              if (rnc != null && rnc.trim().isNotEmpty)
                pw.Text('RNC: ${rnc.trim()}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              pw.SizedBox(height: 6),
              pw.Text(
                'COMPROBANTE DE PAGO DE NÓMINA',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Periodo ${planilla.periodo} · ${planilla.tipoPeriodo}'
                ' · ${_fecha(planilla.fechaInicio)} – ${_fecha(planilla.fechaFin)}',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Estado planilla: ${planilla.estado}',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),

              pw.Text('Empleado',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              _row('Nombre', linea.nombreEmpleado, bold: true),
              if (linea.cargo != null && linea.cargo!.isNotEmpty)
                _row('Cargo', linea.cargo!),
              _row('Salario base', _rd(linea.salarioBase)),

              pw.SizedBox(height: 12),
              pw.Text('Ingresos',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              _row('Sueldo bruto del periodo', _rd(linea.montoBruto)),

              pw.SizedBox(height: 12),
              pw.Text('Descuentos del trabajador',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              _row(
                'AFP (${(CalculadoraNominaRd.tasaAfpTrab * 100).toStringAsFixed(2)}%)',
                _rd(linea.tssAfp),
              ),
              _row(
                'SFS (${(CalculadoraNominaRd.tasaSfsTrab * 100).toStringAsFixed(2)}%)',
                _rd(linea.tssSfs),
              ),
              _row('ISR retenido', _rd(linea.isr)),
              _row('Total descuentos', _rd(descuentos), bold: true),

              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: _row(
                  'NETO A PAGAR',
                  _rd(linea.montoNeto),
                  bold: true,
                  size: 12,
                ),
              ),

              pw.SizedBox(height: 14),
              pw.Text(
                'Aportes del empleador (referencia; no se descuentan del empleado)',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              _row('AFP patronal', _rd(linea.afpPatronal)),
              _row('SFS patronal', _rd(linea.sfsPatronal)),
              _row('SRL / riesgos', _rd(linea.srlPatronal)),
              _row('Fondo de Solidaridad', _rd(linea.fondoSolidaridad)),
              _row('INFOTEP', _rd(linea.infotep)),
              _row('Total aportes patronales', _rd(patronal), bold: true),
              _row('Costo total línea (bruto + patronal)', _rd(linea.costoEmpleador),
                  bold: true),

              pw.Spacer(),
              pw.SizedBox(height: 24),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(children: [
                    pw.Container(width: 160, height: 1, color: PdfColors.grey600),
                    pw.SizedBox(height: 4),
                    pw.Text('Firma empleador', style: const pw.TextStyle(fontSize: 8)),
                  ]),
                  pw.Column(children: [
                    pw.Container(width: 160, height: 1, color: PdfColors.grey600),
                    pw.SizedBox(height: 4),
                    pw.Text('Firma / recibido empleado',
                        style: const pw.TextStyle(fontSize: 8)),
                  ]),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'Documento orientativo. Tasas TSS/ISR 2026 de referencia. '
                'No sustituye declaraciones oficiales ni asesoría formal.',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
              ),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  static Future<void> compartir({
    required Planilla planilla,
    required PlanillaLinea linea,
    String? nombreComercio,
    String? rnc,
  }) async {
    final bytes = await generar(
      planilla: planilla,
      linea: linea,
      nombreComercio: nombreComercio,
      rnc: rnc,
    );
    final safeName = linea.nombreEmpleado
        .replaceAll(RegExp(r'[^a-zA-Z0-9áéíóúÁÉÍÓÚñÑ ]'), '')
        .replaceAll(' ', '_');
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'comprobante_${planilla.periodo}_$safeName.pdf',
    );
  }
}
