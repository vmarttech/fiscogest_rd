import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/ambiente_dgii.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/tipo_ecf.dart';
import 'package:fiscogest_rd/features/e_cf/domain/services/codigo_seguridad_ecf.dart';
import 'package:fiscogest_rd/features/e_cf/domain/services/rfce_rules.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/print/print_formats.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Representación Impresa (RI) de e-CF: datos comerciales + e-NCF + código seguridad + QR.
class RepresentacionImpresaPdf {
  static final _fecha = DateFormat('dd/MM/yyyy HH:mm');

  static Future<void> imprimir({
    required Venta venta,
    required String encf,
    required TipoEcf tipoEcf,
    required String rncEmisor,
    required String razonSocialEmisor,
    required AmbienteDgii ambiente,
    String? xmlFirmado,
    String? trackId,
    String? codigoSeguridad,
    ConfiguracionEntity? empresa,
  }) async {
    final codigo = CodigoSeguridadEcf.resolver(
      codigoPersistido: codigoSeguridad,
      xmlFirmado: xmlFirmado,
    );
    final url = CodigoSeguridadEcf.urlConsulta(
      ambiente: ambiente,
      rncEmisor: rncEmisor,
      encf: encf,
      codigoSeguridad: codigo,
    );
    final rfce = RfceRules.esCandidatoRfce(
      tipo: tipoEcf,
      total: venta.montoTotal,
    );

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PrintFormats.a4.copyWith(
          marginLeft: 28,
          marginRight: 28,
          marginTop: 28,
          marginBottom: 28,
        ),
        build: (ctx) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      razonSocialEmisor.isNotEmpty
                          ? razonSocialEmisor
                          : (empresa?.razonSocial ?? 'Emisor'),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text('RNC: $rncEmisor', style: const pw.TextStyle(fontSize: 10)),
                    if ((empresa?.direccion ?? '').isNotEmpty)
                      pw.Text(empresa!.direccion, style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'REPRESENTACIÓN IMPRESA',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    tipoEcf.descripcion,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  if (rfce)
                    pw.Text(
                      'RFCE (< RD\$250,000)',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  pw.SizedBox(height: 4),
                  pw.Text('e-NCF: $encf',
                      style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Cód. seguridad: $codigo',
                      style: const pw.TextStyle(fontSize: 10)),
                  if (trackId != null && trackId.isNotEmpty)
                    pw.Text('TrackId: $trackId',
                        style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 1),
          pw.Text(
            'Cliente: ${venta.nombreCliente ?? 'Consumidor final'}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Fecha: ${_fecha.format(venta.fecha)}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          if ((venta.numeroFactura ?? '').isNotEmpty)
            pw.Text(
              'NCF local: ${venta.numeroFactura}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Cant.', 'Descripción', 'ITBIS', 'Total'],
            data: [
              for (final d in venta.detalles)
                [
                  d.cantidad.toString(),
                  (d.nombreProducto ?? 'Ítem'),
                  '—',
                  formatRd(d.subtotalLinea ?? d.subtotal),
                ],
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 10),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Subtotal: ${formatRd(venta.montoSubtotal)}',
                    style: const pw.TextStyle(fontSize: 10)),
                pw.Text('ITBIS: ${formatRd(venta.itbis)}',
                    style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  'TOTAL: ${formatRd(venta.montoTotal)}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: url,
                width: 90,
                height: 90,
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Escanee el QR para consultar este e-CF en la DGII.',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      url,
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Esta es una representación impresa del comprobante fiscal electrónico. '
                      'El documento válido es el XML firmado enviado a la DGII.',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }
}
