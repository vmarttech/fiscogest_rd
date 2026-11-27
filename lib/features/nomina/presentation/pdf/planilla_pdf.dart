import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fiscogest_rd/features/nomina/domain/entities/planilla.dart';
import 'package:fiscogest_rd/features/nomina/domain/services/calculadora_nomina_rd.dart';

/// PDF de planilla: líneas de empleados + totales TSS/ISR + costo empleador.
class PlanillaPdf {
  PlanillaPdf._();

  /// RD$1.234.56 (mismo criterio visual que formatRd de la app).
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

  static pw.Widget _h(String t) => pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          t,
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
      );

  static pw.Widget _c(String t, {bool right = false, bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          t,
          textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  static pw.Widget _kpi(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(value,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static Future<Uint8List> generar({
    required Planilla planilla,
    String? nombreComercio,
  }) async {
    final lineas = planilla.lineas;
    final totalBruto =
        planilla.totalBruto > 0
            ? planilla.totalBruto
            : lineas.fold<double>(0, (s, l) => s + l.montoBruto);
    final totalAfp = lineas.fold<double>(0, (s, l) => s + l.tssAfp);
    final totalSfs = lineas.fold<double>(0, (s, l) => s + l.tssSfs);
    final totalIsr =
        planilla.totalIsr > 0
            ? planilla.totalIsr
            : lineas.fold<double>(0, (s, l) => s + l.isr);
    final totalNeto =
        planilla.totalNeto > 0
            ? planilla.totalNeto
            : lineas.fold<double>(0, (s, l) => s + l.montoNeto);
    final totalAfpPat = lineas.fold<double>(0, (s, l) => s + l.afpPatronal);
    final totalSfsPat = lineas.fold<double>(0, (s, l) => s + l.sfsPatronal);
    final totalSrlPat = lineas.fold<double>(0, (s, l) => s + l.srlPatronal);
    final totalFondo = lineas.fold<double>(0, (s, l) => s + l.fondoSolidaridad);
    final totalInfotep = lineas.fold<double>(0, (s, l) => s + l.infotep);
    final totalPatronal =
        totalAfpPat + totalSfsPat + totalSrlPat + totalFondo + totalInfotep;
    final totalCosto =
        planilla.totalCostoEmpleador > 0
            ? planilla.totalCostoEmpleador
            : totalBruto + totalPatronal;
    final totalTssTrab =
        planilla.totalTssTrab > 0
            ? planilla.totalTssTrab
            : totalAfp + totalSfs;

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          pw.Text(
            nombreComercio?.trim().isNotEmpty == true
                ? nombreComercio!.trim()
                : 'FiscoGest',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Planilla de nómina · ${planilla.periodo}',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Estado: ${planilla.estado}'
            '${planilla.tipoPeriodo.isNotEmpty ? ' · Tipo: ${planilla.tipoPeriodo}' : ''}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 12),

          // KPIs resumen
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _kpi('Bruto', _rd(totalBruto)),
              _kpi('TSS trab. (AFP+SFS)', _rd(totalTssTrab)),
              _kpi('ISR', _rd(totalIsr)),
              _kpi('Neto a pagar', _rd(totalNeto)),
              _kpi('Aportes patronales', _rd(totalPatronal)),
              _kpi('Costo empleador', _rd(totalCosto)),
            ],
          ),
          pw.SizedBox(height: 14),

          pw.Text(
            'Detalle por empleado',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.4),
              1: const pw.FlexColumnWidth(1.15),
              2: const pw.FlexColumnWidth(1.0),
              3: const pw.FlexColumnWidth(1.0),
              4: const pw.FlexColumnWidth(1.0),
              5: const pw.FlexColumnWidth(1.15),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _h('Empleado'),
                  _h('Bruto'),
                  _h('AFP'),
                  _h('SFS'),
                  _h('ISR'),
                  _h('Neto'),
                ],
              ),
              ...lineas.map(
                (l) => pw.TableRow(
                  children: [
                    _c(l.nombreEmpleado),
                    _c(_rd(l.montoBruto), right: true),
                    _c(_rd(l.tssAfp), right: true),
                    _c(_rd(l.tssSfs), right: true),
                    _c(_rd(l.isr), right: true),
                    _c(_rd(l.montoNeto), right: true),
                  ],
                ),
              ),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _c('TOTALES', bold: true),
                  _c(_rd(totalBruto), right: true, bold: true),
                  _c(_rd(totalAfp), right: true, bold: true),
                  _c(_rd(totalSfs), right: true, bold: true),
                  _c(_rd(totalIsr), right: true, bold: true),
                  _c(_rd(totalNeto), right: true, bold: true),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.Text(
            'Aportes del empleador (TSS / INFOTEP)',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.2),
              1: const pw.FlexColumnWidth(1.3),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _h('Concepto'),
                  _h('Monto'),
                ],
              ),
              pw.TableRow(children: [
                _c('AFP patronal (${(CalculadoraNominaRd.tasaAfpPat * 100).toStringAsFixed(2)}%)'),
                _c(_rd(totalAfpPat), right: true),
              ]),
              pw.TableRow(children: [
                _c('SFS patronal (${(CalculadoraNominaRd.tasaSfsPat * 100).toStringAsFixed(2)}%)'),
                _c(_rd(totalSfsPat), right: true),
              ]),
              pw.TableRow(children: [
                _c('SRL / riesgos (${(CalculadoraNominaRd.tasaSrlPat * 100).toStringAsFixed(2)}%)'),
                _c(_rd(totalSrlPat), right: true),
              ]),
              pw.TableRow(children: [
                _c('Fondo de Solidaridad (${(CalculadoraNominaRd.tasaFondoSolidaridad * 100).toStringAsFixed(2)}%)'),
                _c(_rd(totalFondo), right: true),
              ]),
              pw.TableRow(children: [
                _c('INFOTEP (${(CalculadoraNominaRd.tasaInfotep * 100).toStringAsFixed(2)}%)'),
                _c(_rd(totalInfotep), right: true),
              ]),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _c('Total aportes patronales', bold: true),
                  _c(_rd(totalPatronal), right: true, bold: true),
                ],
              ),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _c('Costo total empleador (bruto + patronal)', bold: true),
                  _c(_rd(totalCosto), right: true, bold: true),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 14),
          pw.Text(
            'Notas: retenciones del trabajador (AFP ${CalculadoraHint.afp}, '
            'SFS ${CalculadoraHint.sfs}) e ISR según escala DGII orientativa 2026. '
            'Aportes patronales orientativos; verificar topes e indexaciones TSS / DGII / IDOPPRIL. '
            'Este documento no sustituye asesoría formal ni las declaraciones oficiales.',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
          ),
        ],
      ),
    );
    return doc.save();
  }

  static Future<void> compartir({
    required Planilla planilla,
    String? nombreComercio,
  }) async {
    final bytes = await generar(
      planilla: planilla,
      nombreComercio: nombreComercio,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'planilla_${planilla.periodo}.pdf',
    );
  }
}

class CalculadoraHint {
  static const afp = '2.87%';
  static const sfs = '3.04%';
}
