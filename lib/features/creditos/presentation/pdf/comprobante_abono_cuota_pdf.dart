import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuenta_por_cobrar.dart';

/// Comprobante térmico 80mm de abono de cuota (NO fiscal / sin NCF).
class ComprobanteAbonoCuotaPdf {
  ComprobanteAbonoCuotaPdf._();

  static const PdfPageFormat ticket80 = PdfPageFormat(
    80 * PdfPageFormat.mm,
    double.infinity,
    marginAll: 3.5 * PdfPageFormat.mm,
  );

  static Future<Uint8List> generar({
    required CuentaPorCobrar cuenta,
    required double montoAbonado,
    required int cuotaNumero,
    required int cuotaTotal,
    required String metodoPago,
    required DateTime fecha,
    ConfiguracionEntity? empresa,
    String? nombreCliente,
    String? numeroComprobante,
    String? cajero,
    String? cajaTurno,
    double? saldoAnterior,
    double? recibido,
    double? cambio,
    DateTime? vencimientoCuota,
    double? montoPorCuota,
  }) async {
    final doc = pw.Document();
    final cliente = (nombreCliente ?? cuenta.clienteNombre ?? 'Cliente').trim();
    final cxc = cuenta.numero ?? 'CXC-${cuenta.id}';
    final saldoAnt = saldoAnterior ?? cuenta.saldoPendiente;
    final saldoPost = (saldoAnt - montoAbonado).clamp(0.0, double.infinity);
    final pagadas = cuotaNumero.clamp(0, cuotaTotal);
    final pendientes = (cuotaTotal - pagadas).clamp(0, cuotaTotal);
    final montoCuota = montoPorCuota ?? montoAbonado;
    final abo = numeroComprobante ??
        'ABO-${fecha.millisecondsSinceEpoch.toString().substring(7)}';
    final empNombre = _nombreEmpresa(empresa);
    final empRnc = (empresa?.rnc ?? '').trim();
    final empTel = (empresa?.telefono ?? '').trim();
    final empDir = (empresa?.direccion ?? '').trim();

    final fechaStr =
        '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year} '
        '${fecha.hour.toString().padLeft(2, '0')}:'
        '${fecha.minute.toString().padLeft(2, '0')}';

    String? vencStr;
    if (vencimientoCuota != null) {
      final v = vencimientoCuota;
      vencStr =
          '${v.day.toString().padLeft(2, '0')}/'
          '${v.month.toString().padLeft(2, '0')}/'
          '${v.year}';
    }

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
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
              if (empRnc.isNotEmpty)
                pw.Text(
                  'RNC: $empRnc',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                ),
              if (empTel.isNotEmpty)
                pw.Text(
                  'Tel: $empTel',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                ),
              if (empDir.isNotEmpty)
                pw.Text(
                  empDir,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1, color: PdfColors.grey800),
              pw.SizedBox(height: 4),
              pw.Text(
                'COMPROBANTE DE PAGO',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'ABONO DE CUOTA',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#5B21B6'),
                ),
              ),
              pw.Text(
                'No es comprobante fiscal NCF',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 4),
              _dash(),
              pw.SizedBox(height: 4),
              _row('No. comprobante:', abo),
              _row('Fecha:', fechaStr),
              if ((cajero ?? '').trim().isNotEmpty) _row('Cajero:', cajero!.trim()),
              if ((cajaTurno ?? '').trim().isNotEmpty)
                _row('Caja / turno:', cajaTurno!.trim()),
              pw.SizedBox(height: 3),
              _dash(),
              pw.SizedBox(height: 4),
              pw.Text(
                'CLIENTE',
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                cliente,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('Cuenta: $cxc', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 4),
              _dash(),
              pw.SizedBox(height: 5),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F5F3FF'),
                  border: pw.Border.all(
                    color: PdfColor.fromHex('#8B5CF6'),
                    width: 1,
                  ),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'CUOTA PAGADA',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#5B21B6'),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '$cuotaNumero  de  $cuotaTotal',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#5B21B6'),
                      ),
                    ),
                    if (vencStr != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Vencimiento cuota: $vencStr',
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Monto cuota: ${formatRd(montoCuota)}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#7C3AED'),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 5),
              _dash(),
              pw.SizedBox(height: 4),
              pw.Text(
                'DETALLE DEL PAGO',
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 3),
              _row('Saldo anterior:', formatRd(saldoAnt)),
              _row('Monto abonado:', formatRd(montoAbonado), boldValue: true),
              _row('Método de pago:', metodoPago),
              if (recibido != null) _row('Recibido:', formatRd(recibido)),
              if (cambio != null) _row('Cambio:', formatRd(cambio)),
              pw.SizedBox(height: 3),
              pw.Divider(thickness: 1, color: PdfColors.grey800),
              pw.SizedBox(height: 3),
              _row(
                'SALDO PENDIENTE',
                formatRd(saldoPost),
                boldLabel: true,
                boldValue: true,
              ),
              pw.SizedBox(height: 4),
              _dash(),
              pw.SizedBox(height: 4),
              pw.Text(
                'PLAN DE CUOTAS',
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 3),
              _row('Total cuotas:', '$cuotaTotal'),
              _row('Cuotas pagadas:', '$pagadas'),
              _row('Cuotas pendientes:', '$pendientes'),
              _row('Monto por cuota:', formatRd(montoCuota)),
              pw.SizedBox(height: 5),
              _dash(),
              pw.SizedBox(height: 5),
              pw.Text(
                'Este documento certifica el abono aplicado a la cuenta '
                'por cobrar indicada. Conserve este comprobante.',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '¡Gracias por su pago!',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'FiscoGest RD',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey500),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '$abo · $cxc',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey500),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static Future<void> imprimir({
    required CuentaPorCobrar cuenta,
    required double montoAbonado,
    required int cuotaNumero,
    required int cuotaTotal,
    required String metodoPago,
    required DateTime fecha,
    ConfiguracionEntity? empresa,
    String? nombreCliente,
    String? numeroComprobante,
    String? cajero,
    String? cajaTurno,
    double? saldoAnterior,
    double? recibido,
    double? cambio,
    DateTime? vencimientoCuota,
    double? montoPorCuota,
  }) async {
    final bytes = await generar(
      cuenta: cuenta,
      montoAbonado: montoAbonado,
      cuotaNumero: cuotaNumero,
      cuotaTotal: cuotaTotal,
      metodoPago: metodoPago,
      fecha: fecha,
      empresa: empresa,
      nombreCliente: nombreCliente,
      numeroComprobante: numeroComprobante,
      cajero: cajero,
      cajaTurno: cajaTurno,
      saldoAnterior: saldoAnterior,
      recibido: recibido,
      cambio: cambio,
      vencimientoCuota: vencimientoCuota,
      montoPorCuota: montoPorCuota,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Abono_${cuenta.numero ?? cuenta.id}',
      format: ticket80,
    );
  }

  static String _nombreEmpresa(ConfiguracionEntity? e) {
    if (e == null) return 'Empresa';
    if (e.nombreComercial.trim().isNotEmpty) return e.nombreComercial.trim();
    if (e.razonSocial.trim().isNotEmpty) return e.razonSocial.trim();
    return 'Empresa';
  }

  static pw.Widget _dash() => pw.Divider(
        thickness: 0.4,
        color: PdfColors.grey400,
        borderStyle: pw.BorderStyle.dashed,
      );

  static pw.Widget _row(
    String label,
    String value, {
    bool boldLabel = false,
    bool boldValue = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: boldLabel ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: boldValue ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
