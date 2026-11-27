import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fiscogest_rd/features/nomina/domain/services/calculadora_prestaciones_rd.dart';

class LiquidacionPdf {
  LiquidacionPdf._();

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

  static String _f(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.day)}/${p(d.month)}/${d.year}';
  }

  static pw.Widget _row(String a, String b, {bool bold = false}) {
    final st = pw.TextStyle(
      fontSize: 10,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(child: pw.Text(a, style: st)),
          pw.Text(b, style: st),
        ],
      ),
    );
  }

  static Future<Uint8List> generar({
    required String nombreEmpleado,
    required LiquidacionPrestaciones liq,
    String? cargo,
    String? nombreComercio,
  }) async {
    final doc = pw.Document();
    final comercio = (nombreComercio ?? '').trim().isEmpty
        ? 'FiscoGest'
        : nombreComercio!.trim();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(comercio,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('LIQUIDACIÓN DE PRESTACIONES LABORALES',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Divider(),
            _row('Empleado', nombreEmpleado, bold: true),
            if (cargo != null && cargo.isNotEmpty) _row('Cargo', cargo),
            _row('Fecha ingreso', _f(liq.fechaIngreso)),
            _row('Fecha salida', _f(liq.fechaSalida)),
            _row('Antigüedad',
                '${liq.aniosServicio.toStringAsFixed(2)} años (${liq.mesesServicio} meses)'),
            _row('Salario mensual', _rd(liq.salarioMensual)),
            _row('Salario diario (÷ 23.83)', _rd(liq.salarioDiario)),
            pw.SizedBox(height: 12),
            pw.Text('Detalle',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            _row('Preaviso (${liq.diasPreaviso} días)', _rd(liq.montoPreaviso)),
            _row(
              'Auxilio de cesantía (${liq.diasCesantia.toStringAsFixed(1)} días)',
              _rd(liq.montoCesantia),
            ),
            _row(
              'Vacaciones (${liq.diasVacaciones.toStringAsFixed(1)} días)',
              _rd(liq.montoVacaciones),
            ),
            _row('Regalía pascual proporcional', _rd(liq.montoRegalia)),
            pw.Divider(),
            _row('TOTAL A PAGAR', _rd(liq.total), bold: true),
            pw.Spacer(),
            pw.SizedBox(height: 28),
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
                  pw.Text('Firma empleado', style: const pw.TextStyle(fontSize: 8)),
                ]),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Documento orientativo. No sustituye asesoría legal ni el Ministerio de Trabajo.',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  static Future<void> compartir({
    required String nombreEmpleado,
    required LiquidacionPrestaciones liq,
    String? cargo,
    String? nombreComercio,
  }) async {
    final bytes = await generar(
      nombreEmpleado: nombreEmpleado,
      liq: liq,
      cargo: cargo,
      nombreComercio: nombreComercio,
    );
    final safe = nombreEmpleado
        .replaceAll(RegExp(r'[^a-zA-Z0-9áéíóúÁÉÍÓÚñÑ ]'), '')
        .replaceAll(' ', '_');
    await Printing.sharePdf(bytes: bytes, filename: 'liquidacion_$safe.pdf');
  }
}
