import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuenta_por_cobrar.dart';
import 'package:fiscogest_rd/features/creditos/domain/services/i_credito_documento_service.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

class CreditoDocumentoServiceImpl implements ICreditoDocumentoService {
  CreditoDocumentoServiceImpl({
    this.plantillaSolicitudExtra = '',
    this.plantillaContratoExtra = '',
  });

  /// Textos admin (parametros_credito).
  final String plantillaSolicitudExtra;
  final String plantillaContratoExtra;

  static final _fmtFecha = DateFormat('dd/MM/yyyy');
  static final _fmtMonto = NumberFormat('#,##0.00', 'es_DO');

  String _m(double v) => 'RD\$ ${_fmtMonto.format(v)}';

  pw.Widget _titulo(String t) => pw.Text(
    t,
    style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
    textAlign: pw.TextAlign.center,
  );

  pw.Widget _fila(String k, String v) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 140,
          child: pw.Text(
            k,
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        pw.Expanded(child: pw.Text(v, style: const pw.TextStyle(fontSize: 10))),
      ],
    ),
  );

  pw.Widget _lineaFirma(String label) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 28),
    child: pw.Column(
      children: [
        pw.Container(
          width: 200,
          height: 24,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.black, width: 1),
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
      ],
    ),
  );

  List<pw.Widget> _bloqueCliente(Venta venta) => [
    _fila(
      'Cliente',
      venta.nombreCliente?.isNotEmpty == true
          ? venta.nombreCliente!
          : 'ID ${venta.clienteId}',
    ),
    _fila('ID cliente', '${venta.clienteId}'),
    _fila('Cotización', venta.numeroCotizacion),
    _fila('Fecha cotización', _fmtFecha.format(venta.fecha)),
    _fila('Total cotizado', _m(venta.montoTotal)),
  ];

  List<pw.Widget> _bloqueCondiciones(CuentaPorCobrar? c, Venta venta) {
    if (c == null) {
      return [
        _fila('Abono inicial', _m(venta.abonoInicial)),
        _fila(
          'Vencimiento',
          venta.vencimiento != null
              ? _fmtFecha.format(venta.vencimiento!)
              : 'Por definir',
        ),
        pw.Text(
          'Complete las condiciones en «Editar abono, plazo y cuotas» '
          'para un documento completo.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ];
    }
    final saldo = c.saldoFinanciado;
    final cuota = c.numeroCuotas > 0
        ? (c.totalAPagar / c.numeroCuotas)
        : c.totalAPagar;
    return [
      _fila('Abono inicial', _m(c.abonoInicial)),
      _fila('Saldo a financiar', _m(saldo)),
      _fila('Interés (monto)', _m(c.montoInteres)),
      _fila('Total a pagar', _m(c.totalAPagar)),
      _fila('N° cuotas', '${c.numeroCuotas}'),
      _fila(
        'Cuota estimada',
        c.numeroCuotas > 1 ? _m(cuota) : _m(c.totalAPagar),
      ),
      _fila('Plazo (días)', '${c.plazoDias}'),
      _fila('Vencimiento', _fmtFecha.format(c.fechaVencimiento)),
      if (c.observaciones != null && c.observaciones!.isNotEmpty)
        _fila('Observaciones', c.observaciones!),
    ];
  }

  List<pw.Widget> _detalleProductos(Venta venta) {
    if (venta.detalles.isEmpty) {
      return [
        pw.Text(
          'Sin líneas de producto en el documento.',
          style: const pw.TextStyle(fontSize: 9),
        ),
      ];
    }
    return [
      pw.TableHelper.fromTextArray(
        headers: ['Producto', 'Cant.', 'P. unit.', 'Subtotal'],
        data: [
          for (final d in venta.detalles)
            [
              d.nombreProducto ?? 'Producto',
              '${d.cantidad}',
              _m(d.precioUnitario),
              _m(d.subtotalLinea ?? d.subtotal),
            ],
        ],
        headerStyle: const pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
        ),
        cellStyle: const pw.TextStyle(fontSize: 8),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      ),
    ];
  }

  @override
  Future<Uint8List> generarPdfSolicitud({
    required Venta venta,
    CuentaPorCobrar? condiciones,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => [
          _titulo('FISCOGEST RD'),
          pw.SizedBox(height: 4),
          _titulo('SOLICITUD DE CRÉDITO'),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Datos del solicitante / operación',
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
          pw.SizedBox(height: 6),
          ..._bloqueCliente(venta),
          pw.SizedBox(height: 12),
          pw.Text(
            'Condiciones propuestas',
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
          pw.SizedBox(height: 6),
          ..._bloqueCondiciones(condiciones, venta),
          pw.SizedBox(height: 12),
          pw.Text(
            'Detalle de la cotización',
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
          pw.SizedBox(height: 6),
          ..._detalleProductos(venta),
          pw.SizedBox(height: 16),
          pw.Text(
            'Declaración del solicitante',
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
          pw.SizedBox(height: 6),
          if (plantillaSolicitudExtra.trim().isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              plantillaSolicitudExtra.trim(),
              style: const pw.TextStyle(fontSize: 9),
              textAlign: pw.TextAlign.justify,
            ),
          ],
          pw.Text(
            'Declaro que la información suministrada es verdadera y autorizo '
            'a FiscoGest RD / el establecimiento a verificar mis datos y '
            'referencias para la evaluación de este crédito. Me comprometo a '
            'cumplir las condiciones que se aprueben y consten en el contrato.',
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Referencias (completar a mano si aplica)',
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
          ),
          pw.SizedBox(height: 8),
          _fila('Referencia 1', 'Nombre: _____________  Tel: _____________'),
          _fila('Referencia 2', 'Nombre: _____________  Tel: _____________'),
          pw.SizedBox(height: 8),
          _fila('Cédula / RNC', '_______________________________'),
          _fila('Dirección', '_______________________________'),
          _fila('Teléfono', '_______________________________'),
          pw.SizedBox(height: 24),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _lineaFirma('Firma del solicitante'),
              _lineaFirma('Analista de crédito'),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Center(
            child: pw.Text(
              'Documento generado el ${_fmtFecha.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  @override
  Future<Uint8List> generarPdfContrato({
    required Venta venta,
    required CuentaPorCobrar condiciones,
  }) async {
    final doc = pw.Document();
    final nro = venta.numeroCotizacion;
    final cuota = condiciones.numeroCuotas > 0
        ? condiciones.totalAPagar / condiciones.numeroCuotas
        : condiciones.totalAPagar;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => [
          _titulo('FISCOGEST RD'),
          pw.SizedBox(height: 4),
          _titulo('CONTRATO DE CRÉDITO / COMPRA A PLAZO'),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Entre el establecimiento comercial (EL ACREEDOR) y el cliente '
            'identificado a continuación (EL DEUDOR), se conviene el presente '
            'contrato de crédito bajo las siguientes cláusulas:',
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            '1. Identificación',
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
          pw.SizedBox(height: 4),
          ..._bloqueCliente(venta),
          pw.SizedBox(height: 10),
          pw.Text(
            '2. Objeto y monto',
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'El DEUDOR adquiere los bienes/servicios detallados en la '
            'cotización $nro por un valor de ${_m(venta.montoTotal)}, '
            'financiando el saldo según las condiciones del numeral 3.',
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 8),
          ..._detalleProductos(venta),
          pw.SizedBox(height: 10),
          pw.Text(
            '3. Condiciones de pago',
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
          pw.SizedBox(height: 4),
          ..._bloqueCondiciones(condiciones, venta),
          if (condiciones.numeroCuotas > 1)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                'Cuota mensual estimada: ${_m(cuota)} '
                '(${condiciones.numeroCuotas} cuotas).',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
          pw.SizedBox(height: 10),
          pw.Text(
            '4. Obligaciones del DEUDOR',
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'a) Pagar puntualmente las cuotas en las fechas pactadas.\n'
            'b) Informar cambios de domicilio o teléfono.\n'
            'c) Conservar los bienes en buen estado mientras exista saldo.\n'
            'd) Cubrir cargos por mora según política del establecimiento, '
            'si aplica.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            '5. Incumplimiento',
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'El atraso en el pago podrá generar intereses moratorios y/o '
            'gestión de cobro conforme a la ley y a las políticas internas. '
            'El ACREEDOR se reserva las acciones legales pertinentes.',
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 10),
          if (plantillaContratoExtra.trim().isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              'Cláusulas adicionales',
              style: const pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              plantillaContratoExtra.trim(),
              style: const pw.TextStyle(fontSize: 9),
              textAlign: pw.TextAlign.justify,
            ),
          ],
          pw.Text(
            '6. Aceptación',
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Ambas partes declaran haber leído y aceptado este contrato en '
            'todas sus partes. Se firma en la fecha indicada.',
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 28),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [_lineaFirma('El DEUDOR'), _lineaFirma('El ACREEDOR')],
          ),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              'Contrato · $nro · ${_fmtFecha.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  @override
  Future<void> imprimirSolicitud({
    required Venta venta,
    CuentaPorCobrar? condiciones,
  }) async {
    final bytes = await generarPdfSolicitud(
      venta: venta,
      condiciones: condiciones,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Solicitud_${venta.numeroCotizacion}',
    );
  }

  @override
  Future<void> imprimirContrato({
    required Venta venta,
    required CuentaPorCobrar condiciones,
  }) async {
    final bytes = await generarPdfContrato(
      venta: venta,
      condiciones: condiciones,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Contrato_${venta.numeroCotizacion}',
    );
  }

  @override
  Future<String> exportarSolicitudPdf({
    required Venta venta,
    CuentaPorCobrar? condiciones,
  }) async {
    final bytes = await generarPdfSolicitud(
      venta: venta,
      condiciones: condiciones,
    );
    final dir = await getTemporaryDirectory();
    final ref = venta.numeroCotizacion.replaceAll(RegExp(r'[^\w-]'), '_');
    final path = '${dir.path}/solicitud_credito_$ref.pdf';
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  @override
  Future<String> exportarContratoPdf({
    required Venta venta,
    required CuentaPorCobrar condiciones,
  }) async {
    final bytes = await generarPdfContrato(
      venta: venta,
      condiciones: condiciones,
    );
    final dir = await getTemporaryDirectory();
    final ref = venta.numeroCotizacion.replaceAll(RegExp(r'[^\w-]'), '_');
    final path = '${dir.path}/contrato_credito_$ref.pdf';
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  @override
  Future<void> enviarSolicitudPorCorreo({
    required Venta venta,
    CuentaPorCobrar? condiciones,
    String correoDestinatario = '',
  }) async {
    final ruta = await exportarSolicitudPdf(
      venta: venta,
      condiciones: condiciones,
    );
    final nro = venta.numeroCotizacion;
    await Share.shareXFiles(
      [XFile(ruta, mimeType: 'application/pdf')],
      text: correoDestinatario.isNotEmpty
          ? 'Destinatario: $correoDestinatario\nSolicitud de crédito $nro'
          : 'Solicitud de crédito $nro',
      subject: 'Solicitud de crédito $nro — FiscoGest RD',
    );
  }

  @override
  Future<void> enviarContratoPorCorreo({
    required Venta venta,
    required CuentaPorCobrar condiciones,
    String correoDestinatario = '',
  }) async {
    final ruta = await exportarContratoPdf(
      venta: venta,
      condiciones: condiciones,
    );
    final nro = venta.numeroCotizacion;
    await Share.shareXFiles(
      [XFile(ruta, mimeType: 'application/pdf')],
      text: correoDestinatario.isNotEmpty
          ? 'Destinatario: $correoDestinatario\nContrato de crédito $nro'
          : 'Contrato de crédito $nro',
      subject: 'Contrato de crédito $nro — FiscoGest RD',
    );
  }

  @override
  Future<Uint8List> generarPdfCronograma({
    required CuentaPorCobrar cuenta,
  }) async {
    final fmt = NumberFormat('#,##0.00', 'es_DO');
    final fmtFecha = DateFormat('dd/MM/yyyy');
    final cuotas = cuenta.planPago?.cuotas ?? const [];
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          pw.Text(
            'CRONOGRAMA DE PAGOS',
            style: const pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '${cuenta.clienteNombre}  ·  Cuenta #${cuenta.id ?? ''}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2),
              1: const pw.FlexColumnWidth(2.2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1.8),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _celda('N°', bold: true),
                  _celda('Vencimiento', bold: true),
                  _celda('Monto', bold: true, align: pw.TextAlign.right),
                  _celda('Estado', bold: true),
                ],
              ),
              for (final q in cuotas)
                pw.TableRow(
                  children: [
                    _celda('${q.numeroCuota}'),
                    _celda(fmtFecha.format(q.fechaVencimiento)),
                    _celda(
                      'RD\$ ${fmt.format(q.montoTotal)}',
                      align: pw.TextAlign.right,
                    ),
                    _celda(q.pagada ? 'Pagada' : 'Pendiente'),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _celda(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Future<void> imprimirCronograma({required CuentaPorCobrar cuenta}) async {
    final bytes = await generarPdfCronograma(cuenta: cuenta);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Cronograma_${cuenta.id ?? 'cuenta'}',
    );
  }
}
