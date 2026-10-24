import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';
import 'package:fiscogest_rd/features/transferencias/domain/entities/transferencia.dart';

/// Manifiesto de transferencia inter-almacén + packing/batch list (A4).
class ManifiestoTransferenciaPdf {
  ManifiestoTransferenciaPdf._();

  static final _fmtFecha = DateFormat('dd/MM/yyyy');
  static final _fmtNum = NumberFormat('#,##0.00', 'es_DO');

  static Future<Uint8List> generar({
    required Transferencia t,
    required ConfiguracionEntity cfg,
    String? transportista,
    String? observaciones,
  }) async {
    final doc = pw.Document();
    final nro = 'TR-${t.fecha.year}-${(t.id ?? 0).toString().padLeft(5, '0')}';
    final mnf = 'MNF-${(t.id ?? 0).toString().padLeft(5, '0')}';
    final codigo = (t.productoCodigo ?? '').trim().isEmpty
        ? 'PROD-${t.productoId}'
        : t.productoCodigo!.trim();
    final nombre = (t.productoNombre ?? 'Producto ${t.productoId}').trim();
    final origen =
        t.origenNombre ?? 'Almacén ${t.almacenOrigenId}';
    final destino =
        t.destinoNombre ?? 'Almacén ${t.almacenDestinoId}';
    final cant = t.cantidad;
    final nota = (observaciones ?? t.nota ?? '').trim();

    final headerStyle = pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey800,
    );
    final cellStyle = const pw.TextStyle(fontSize: 8);
    final titleBlue = PdfColor.fromInt(0xFF1E3A5F);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 40),
        build: (ctx) => [
          // Título
          pw.Center(
            child: pw.Text(
              (cfg.transfTituloManifiesto.trim().isEmpty
                      ? 'MANIFIESTO DE TRANSFERENCIA INTER-ALMACÉN'
                      : cfg.transfTituloManifiesto.trim())
                  .toUpperCase(),
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: titleBlue,
              ),
            ),
          ),
          pw.SizedBox(height: 2),
          if ((cfg.transfSubtituloManifiesto).trim().isNotEmpty)
            pw.Center(
              child: pw.Text(
                cfg.transfSubtituloManifiesto.trim(),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey700,
                ),
              ),
            ),
          if (cfg.docMostrarLogo ||
              (cfg.nombreComercial).trim().isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                cfg.nombreComercial.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            if (cfg.docMostrarRnc && cfg.rnc.trim().isNotEmpty)
              pw.Center(
                child: pw.Text(
                  'RNC: ${cfg.rnc}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
          ],
          pw.SizedBox(height: 14),

          // Cabecera 2 columnas
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey200),
              borderRadius: pw.BorderRadius.circular(4),
              color: PdfColors.blueGrey50,
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _kv('Nº Documento', nro, headerStyle),
                      _kv('Almacén Origen', origen, headerStyle),
                      _kv('Almacén Destino', destino, headerStyle),
                      _kv('Tipo Movimiento', 'Transferencia de Producto',
                          headerStyle),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _kv('Fecha Emisión', _fmtFecha.format(t.fecha),
                          headerStyle),
                      _kv('Fecha Envío', _fmtFecha.format(t.fecha),
                          headerStyle),
                      _kv(
                        'Transportista / Operador',
                        () {
                          final v = (transportista ??
                                  cfg.transfTransportistaDefault)
                              .trim();
                          return v.isEmpty ? '—' : v;
                        }(),
                        headerStyle,
                      ),
                      _kv('Nº Manifiesto Ruta', mnf, headerStyle),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          pw.Text(
            'Detalle de Carga y Desglose de Lotes (Packing & Batch List)',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: titleBlue,
            ),
          ),
          pw.SizedBox(height: 8),

          // Tabla
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.blueGrey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.3),
              1: const pw.FlexColumnWidth(2.4),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(0.9),
              4: const pw.FlexColumnWidth(0.8),
              5: const pw.FlexColumnWidth(1.2),
              6: const pw.FlexColumnWidth(0.9),
              7: const pw.FlexColumnWidth(0.9),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E3A5F)),
                children: [
                  _th('Código / EAN'),
                  _th('Descripción Producto'),
                  _th('Nº Lote (Batch)'),
                  _th('F. Caducidad'),
                  _th('Cant. (Uds)'),
                  _th('Bultos / Caja'),
                  _th('P. Neto (Kg)'),
                  _th('P. Bruto (Kg)'),
                ],
              ),
              pw.TableRow(
                children: [
                  _td(codigo, cellStyle),
                  _td(nombre, cellStyle),
                  _td('—', cellStyle),
                  _td('—', cellStyle),
                  _td(_fmtNum.format(cant), cellStyle, align: pw.TextAlign.right),
                  _td('—', cellStyle),
                  _td('—', cellStyle, align: pw.TextAlign.right),
                  _td('—', cellStyle, align: pw.TextAlign.right),
                ],
              ),
              // Totales
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
                children: [
                  _td('TOTALES', cellStyle, bold: true),
                  _td('', cellStyle),
                  _td('', cellStyle),
                  _td('', cellStyle),
                  _td(_fmtNum.format(cant), cellStyle,
                      bold: true, align: pw.TextAlign.right),
                  _td('—', cellStyle, bold: true),
                  _td('—', cellStyle, bold: true, align: pw.TextAlign.right),
                  _td('—', cellStyle, bold: true, align: pw.TextAlign.right),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          pw.Text(
            'Observaciones / Instrucciones de Carga',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: titleBlue,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey200),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              nota.isEmpty
                  ? (cfg.transfObservacionesDefault.trim().isEmpty
                      ? 'Verificar cantidades y estado del producto al momento de la recepción.'
                      : cfg.transfObservacionesDefault.trim())
                  : nota,
              style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.3),
            ),
          ),
          // Firmas
          if (cfg.transfMostrarFirmas) ...[
            pw.SizedBox(height: 36),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _firma('Despachado por (Origen)', 'Firma y Sello'),
                _firma('Transportista (Ruta)', 'Firma y Cédula'),
                _firma('Recibido por (Destino)', 'Firma y Sello'),
              ],
            ),
          ],

          if ((cfg.docPiePagina).trim().isNotEmpty) ...[
            pw.SizedBox(height: 28),
            pw.Center(
              child: pw.Text(
                cfg.docPiePagina,
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  static Future<void> imprimir({
    required Transferencia t,
    required ConfiguracionEntity cfg,
    String? transportista,
    String? observaciones,
  }) async {
    final bytes = await generar(
      t: t,
      cfg: cfg,
      transportista: transportista,
      observaciones: observaciones,
    );
    final name =
        'Manifiesto_TR_${t.fecha.year}_${(t.id ?? 0).toString().padLeft(5, '0')}.pdf';
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: name,
    );
  }

  static pw.Widget _kv(String k, String v, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: '$k: ', style: style),
            pw.TextSpan(
              text: v,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _th(String t) => pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          t,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      );

  static pw.Widget _td(
    String t,
    pw.TextStyle style, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          t,
          textAlign: align,
          style: bold
              ? style.copyWith(fontWeight: pw.FontWeight.bold)
              : style,
        ),
      );

  static pw.Widget _firma(String titulo, String sub) {
    return pw.Column(
      children: [
        pw.Container(
          width: 140,
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey700)),
          ),
          padding: const pw.EdgeInsets.only(top: 4),
          child: pw.Column(
            children: [
              pw.Text(
                titulo,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                sub,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
