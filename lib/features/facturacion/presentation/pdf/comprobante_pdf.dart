// ignore_for_file: unused_element
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:fiscogest_rd/core/print/print_formats.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:fiscogest_rd/features/impuestos/domain/services/resolver_tasa_itbis.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/ambiente_dgii.dart';
import 'package:fiscogest_rd/features/e_cf/domain/services/codigo_seguridad_ecf.dart';

/// Comprobante fiscal impreso (B01 crédito fiscal · B02 consumidor final).
/// Estructura orientada a uso comercial en RD (DGII serie B).
class ComprobantePdf {
  /// Ticket térmico 80 mm (ancho fijo, alto según contenido).
  static const double _anchoTicket80 = 80 * PdfPageFormat.mm;
  static const double _margenTicket80 = 3 * PdfPageFormat.mm;

  // El alto de rollo no tiene límite fijo; cada comprobante genera su propia
  // página finita según el contenido antes de enviarse a imprimir.
  static const PdfPageFormat formatoTicket80 = PdfPageFormat.roll80;

  /// Evita el alto infinito, que algunos controladores sustituyen por A4/Letter.
  static PdfPageFormat _formatoTicketPara(
    Venta venta,
    ConfiguracionEntity? empresa,
  ) {
    final valores = <String>[
      if ((empresa?.docMostrarLogo ?? true) &&
          (empresa?.logoUrl ?? '').isNotEmpty)
        'logo',
      emisorNombre,
      if ((empresa?.docMostrarRnc ?? true)) empresa?.rnc ?? '',
      if ((empresa?.docMostrarTelefono ?? true)) empresa?.telefono ?? '',
      if ((empresa?.docMostrarCorreo ?? true)) empresa?.correo ?? '',
      if ((empresa?.docMostrarDireccion ?? true)) empresa?.direccion ?? '',
      if (empresa?.docMostrarCliente ?? true) ...[
        venta.nombreCliente ?? 'Consumidor Final',
        venta.clienteTelefono ?? '',
        venta.clienteDireccion ?? '',
      ],
      venta.numeroCotizacion,
      venta.numeroFactura ?? '',
      DateFormat('dd/MM/yyyy HH:mm').format(venta.fecha),
      'Status: Pagado',
      venta.formaPago,
      'Descripción',
      'Cant. Precio Subtotal',
      ...venta.detalles.expand(
        (d) => [
          d.nombreProducto ?? 'Ítem',
          d.ofertaNombre ?? '',
          if (d.precioOriginal != null) _money(d.precioOriginal!),
          _money(d.precioUnitario),
          (_money(d.subtotalLinea ?? d.subtotal) +
              sufijoTasaLinea(
                d.tasaImpuesto,
                ceroEsExento: false,
              )),
        ],
      ),
      _money(venta.montoSubtotal),
      _money(venta.montoDescuento),
      _money(venta.itbis),
      _money(venta.costoEnvio),
      _money(venta.montoTotal),
      empresa?.docPiePagina ?? '',
    ];
    final lineas = valores.fold<int>(0, (total, texto) {
      final largo = texto.trim().length;
      return total + (largo == 0 ? 0 : (largo / 32).ceil());
    });
    var altoMm = 96 + lineas * 4.0;
    for (final d in venta.detalles) {
      altoMm += 14;
      if ((d.ofertaNombre ?? '').trim().isNotEmpty) altoMm += 4;
      if (d.precioOriginal != null) altoMm += 4;
      if (d.montoDescuento > 0.001 || d.descuentoPorcentaje > 0.001) {
        altoMm += 4;
      }
    }
    if (venta.costoEnvio > 0.0001) altoMm += 12;
    final ncfTicket = (venta.numeroFactura ?? '').trim();
    if (ncfTicket.isNotEmpty) {
      altoMm += ncfTicket.startsWith('E') ? 78 : 16;
    }
    if ((empresa?.docPiePagina ?? '').trim().isEmpty) altoMm += 14;
    return PdfPageFormat(
      _anchoTicket80,
      altoMm * PdfPageFormat.mm,
      marginLeft: _margenTicket80,
      marginRight: _margenTicket80,
      marginTop: _margenTicket80,
      marginBottom: _margenTicket80,
    );
  }

  // Datos del emisor: los asigna imprimirFactura() con la configuración guardada.
  static ConfiguracionEntity? _empresa;
  static String emisorNombre = 'FiscoGest RD';
  static String emisorRnc = '000000000';
  static String emisorDir = 'Santo Domingo, República Dominicana';
  static String emisorTel = '';
  static String emisorEmail = '';

  static String _money(double v) => formatRd(v);
  static final _fecha = DateFormat('dd/MM/yyyy HH:mm');

  /// [modo]: null = solo layout; true = compartir; false = imprimir.
  /// Si [mostrarOpciones] es true, el llamador debe pasar un callback UI.
  static Future<void> imprimirFactura(
    Venta v, {
    ConfiguracionEntity? empresa,
    bool compartir = false,
    String? rncCliente,
    String? direccionCliente,
    String? telefonoCliente,

    String? codigoSeguridad,
    AmbienteDgii? ambienteDgii,
  }) async {
    final ncf = (v.numeroFactura ?? '').trim();
    final simple = empresa?.modoSimplificado == true;
    if (ncf.isEmpty && !simple) {
      throw StateError('Sin NCF: no se puede imprimir comprobante fiscal');
    }
    if (v.detalles.isEmpty) {
      assert(() {
        // ignore: avoid_print
        print('AVISO ComprobantePdf: venta sin detalles (id=${v.id})');
        return true;
      }());
    }
    final doc = await _buildDocumento(
      v,
      empresa: empresa,
      rncCliente: rncCliente,
      direccionCliente: direccionCliente,
      telefonoCliente: telefonoCliente,
      codigoSeguridad: codigoSeguridad,
      ambienteDgii: ambienteDgii,
    );
    final bytes = await doc.save();
    if (compartir) {
      await Printing.sharePdf(bytes: bytes, filename: 'Factura_$ncf.pdf');
    } else {
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'Factura_$ncf.pdf',
        format: _formatoTicketPara(v, empresa),
      );
    }
  }

  /// Bytes listos + nombre de archivo (para menú Imprimir / Enviar).
  static Future<({Uint8List bytes, String filename})> prepararFactura(
    Venta v, {
    ConfiguracionEntity? empresa,

    String? codigoSeguridad,
    AmbienteDgii? ambienteDgii,
  }) async {
    final ncf = (v.numeroFactura ?? '').trim();
    final simple = empresa?.modoSimplificado == true;
    if (ncf.isEmpty && !simple) {
      throw StateError('Sin NCF: no se puede generar comprobante fiscal');
    }
    final doc = await _buildDocumento(
      v,
      empresa: empresa,
      codigoSeguridad: codigoSeguridad,
      ambienteDgii: ambienteDgii,
    );
    final bytes = await doc.save();
    return (bytes: bytes, filename: 'Factura_$ncf.pdf');
  }

  static Future<void> compartirBytes(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  static Future<void> imprimirBytes(Uint8List bytes, String filename) async {
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: filename,
      format: formatoTicket80,
    );
  }

  /// Genera bytes del PDF (para guardar archivo o compartir).
  static Future<Uint8List> generarBytes(
    Venta v, {
    ConfiguracionEntity? empresa,

    String? codigoSeguridad,
    AmbienteDgii? ambienteDgii,
  }) async {
    final doc = await _buildDocumento(
      v,
      empresa: empresa,
      codigoSeguridad: codigoSeguridad,
      ambienteDgii: ambienteDgii,
    );
    return doc.save();
  }

  static Future<pw.Document> _buildDocumento(
    Venta v, {
    ConfiguracionEntity? empresa,
    String? rncCliente,
    String? direccionCliente,
    String? telefonoCliente,

    String? codigoSeguridad,
    AmbienteDgii? ambienteDgii,
  }) async {
    _empresa = empresa;
    // Modo simplificado: no mostrar NCF ni desglose ITBIS aunque flags docs digan sí
    if (empresa?.modoSimplificado == true) {
      // los checks usan _empresa?.docMostrar* — se anulan abajo con helpers
    }
    emisorNombre = (empresa?.nombreComercial.isNotEmpty == true)
        ? empresa!.nombreComercial
        : (empresa?.razonSocial.isNotEmpty == true)
        ? empresa!.razonSocial
        : 'Empresa';
    emisorRnc = empresa?.rnc ?? '';
    emisorDir = empresa?.direccion ?? '';
    emisorTel = empresa?.telefono ?? '';
    emisorEmail = empresa?.correo ?? '';

    final ncf = (v.numeroFactura ?? '').trim();
    final simple = empresa?.modoSimplificado == true;
    final esB01 = !simple && ncf.startsWith('B01');
    final esB02 = !simple && ncf.startsWith('B02');
    final titulo = simple
        ? 'COMPROBANTE DE VENTA'
        : esB01
        ? 'FACTURA DE CRÉDITO FISCAL'
        : esB02
        ? 'FACTURA PARA CONSUMIDOR FINAL'
        : 'COMPROBANTE DE VENTA';

    final cliente = (v.nombreCliente ?? 'Consumidor Final').trim();
    final formaPago = () {
      try {
        final fp = v.formaPago;
        if (fp.isNotEmpty) return fp;
      } catch (_) {}
      try {
        final tp = v.tipoPago;
        if (tp.isNotEmpty) return tp;
      } catch (_) {}
      return 'Efectivo';
    }();
    final fecha = v.fecha;

    final doc = pw.Document(title: 'Factura $ncf', author: emisorNombre);

    pw.MemoryImage? logoImage;
    final logoPath = empresa?.logoUrl ?? '';
    if ((empresa?.docMostrarLogo ?? true) &&
        logoPath.isNotEmpty &&
        File(logoPath).existsSync()) {
      try {
        logoImage = pw.MemoryImage(File(logoPath).readAsBytesSync());
      } catch (_) {}
    }

    doc.addPage(
      pw.Page(
        pageFormat: _formatoTicketPara(v, empresa),
        build: (ctx) => _ticketBody(
          v: v,
          empresa: empresa,
          simple: simple,
          ncf: ncf,
          titulo: titulo,
          cliente: cliente,
          rncCliente: rncCliente,
          direccionCliente: direccionCliente,
          telefonoCliente: telefonoCliente,
          formaPago: formaPago,
          fecha: fecha,
          logoImage: logoImage,
          codigoSeguridad: codigoSeguridad,
          ambienteDgii: ambienteDgii,
        ),
      ),
    );
    return doc;
  }

  static pw.Widget _header({
    required String titulo,
    required String tipoLabel,
    required String ncf,
    pw.MemoryImage? logo,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null) ...[
              pw.Container(
                width: 56,
                height: 56,
                margin: const pw.EdgeInsets.only(right: 10),
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
            ],
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    emisorNombre,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  if ((_empresa?.docMostrarRnc ?? true) && emisorRnc.isNotEmpty)
                    pw.Text(
                      'RNC: $emisorRnc',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  if ((_empresa?.docMostrarDireccion ?? true) &&
                      emisorDir.isNotEmpty)
                    pw.Text(emisorDir, style: const pw.TextStyle(fontSize: 9)),
                  if ((_empresa?.docMostrarTelefono ?? true) &&
                      emisorTel.isNotEmpty)
                    pw.Text(
                      'Tel: $emisorTel',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  if ((_empresa?.docMostrarCorreo ?? true) &&
                      emisorEmail.isNotEmpty)
                    pw.Text(
                      emisorEmail,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                ],
              ),
            ),
            pw.Container(
              width: 200,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey700, width: 1),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    titulo,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(tipoLabel, style: const pw.TextStyle(fontSize: 8)),
                  pw.SizedBox(height: 6),
                  if ((_empresa?.modoSimplificado != true) &&
                      (_empresa?.docMostrarNcf ?? true)) ...[
                    pw.Text(
                      'NCF',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      ncf,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 1.2, color: PdfColors.grey800),
      ],
    );
  }

  static pw.Widget _bloqueEmisorCliente({
    required String cliente,
    String? rncCliente,
    String? direccionCliente,
    String? telefonoCliente,
    required bool esB01,
    required Venta venta,
    required DateTime fecha,
  }) {
    final cot = venta.numeroCotizacion;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CLIENTE',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  cliente,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if ((direccionCliente ?? '').trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Dir: ${(direccionCliente ?? '').trim()}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
                if ((telefonoCliente ?? '').trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Tel: ${(telefonoCliente ?? '').trim()}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
                if ((rncCliente ?? '').trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'RNC / Cédula: ${(rncCliente ?? '').trim()}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ] else if (esB01) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'RNC / Cédula: (completar en ficha del cliente)',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.orange700,
                    ),
                  ),
                ] else ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Consumidor final · sin crédito fiscal',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Container(
          width: 180,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _kv('Fecha', _fecha.format(fecha)),
              _kv('Cotización', cot),
              _kv('Condición', esB01 ? 'Crédito fiscal' : 'Contado / consumo'),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _kv(String k, String val) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 70,
            child: pw.Text(
              k,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              val,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tablaProductos(List<DetalleVenta> detalles) {
    final headers = ['#', 'Descripción', 'Cant.', 'Precio', 'Importe'];
    final rows = <List<String>>[];
    if (detalles.isEmpty) {
      rows.add(['—', 'Sin líneas de detalle en base de datos', '—', '—', '—']);
    } else {
      for (var i = 0; i < detalles.length; i++) {
        final d = detalles[i];
        final cant = d.cantidad;
        final precio = d.precioUnitario;
        final imp = cant * precio;
        final desc = (d.nombreProducto ?? 'Ítem');
        rows.add([
          '${i + 1}',
          desc,
          _fmtQty(cant.toDouble()),
          _money(precio),
          _money(imp),
        ]);
      }
    }

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FixedColumnWidth(28),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(45),
        3: const pw.FixedColumnWidth(70),
        4: const pw.FixedColumnWidth(75),
      },
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      headerHeight: 22,
      cellHeight: 20,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    );
  }

  static String _fmtQty(double q) {
    if (q == q.roundToDouble()) return q.toInt().toString();
    return q.toStringAsFixed(2);
  }

  static pw.Widget _totales({
    required double subtotal,
    required double itbis,
    required double total,
    required String formaPago,
    double costoEnvio = 0,
    double montoDescuento = 0,
    String etiquetaItbis = 'ITBIS',
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Forma de pago: ${formaPago.isEmpty ? 'Efectivo' : formaPago}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 6),
              if ((_empresa?.modoSimplificado != true) &&
                  (_empresa?.docMostrarItbisDesglose ?? true))
                pw.Text(
                  '$etiquetaItbis discriminado en esta factura.',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
            ],
          ),
        ),
        pw.Container(
          width: 200,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey600),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            children: [
              if ((_empresa?.modoSimplificado != true) &&
                  (_empresa?.docMostrarItbisDesglose ?? true)) ...[
                _totalRow('Subtotal', _money(subtotal)),
                if (montoDescuento > 0.001)
                  _totalRow('Descuento', '- ${_money(montoDescuento)}'),
                if (costoEnvio > 0.001)
                  _totalRow('Envío / delivery', _money(costoEnvio)),
                _totalRow(etiquetaItbis, _money(itbis)),
                pw.Divider(color: PdfColors.grey600),
              ],
              _totalRow('TOTAL', _money(total), bold: true),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _totalRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: bold ? 11 : 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: bold ? 11 : 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _leyendaLegal({required bool esB01, required String ncf}) {
    final texto = esB01
        ? 'Este comprobante (NCF $ncf) es Factura de Crédito Fiscal. '
              'Permite al comprador sustentar costos y crédito de ITBIS ante la DGII, '
              'siempre que el RNC del cliente esté correctamente registrado.'
        : 'Este comprobante (NCF $ncf) es Factura de Consumo (consumidor final). '
              'No otorga crédito fiscal de ITBIS ni sustenta costos del ISR al comprador.';

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        texto,
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }

  static pw.Widget _footer(pw.Context ctx, String ncf) {
    final pie = (_empresa?.docPiePagina ?? '').trim();
    final ncfTxt =
        ((_empresa?.modoSimplificado != true) &&
            (_empresa?.docMostrarNcf ?? true))
        ? 'NCF: $ncf · '
        : '';
    return pw.Column(
      children: [
        if (pie.isNotEmpty) ...[
          pw.Text(
            pie,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
        ],
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '${ncfTxt}Generado con FiscoGest RD',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            ),
            pw.Text(
              'Pág. ${ctx.pageNumber}/${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  /// Nota de crédito (B04) - estructura básica alineada.
  static Future<void> imprimirNc({
    Venta? ventaOriginal,
    String? ncfOrigen,
    String? cliente,
    required String ncfNc,
    required double monto,
    String? motivo,
  }) async {
    final ncfAfectado = ncfOrigen ?? (ventaOriginal?.numeroFactura ?? '-');
    final nombreCliente = (cliente != null && cliente.isNotEmpty)
        ? cliente
        : (ventaOriginal?.nombreCliente ?? '-');
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PrintFormats.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 40),
        build: (ctx) => [
          pw.Text(
            'NOTA DE CRÉDITO',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'B04 · Ajuste sobre factura',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'NCF Nota de crédito: $ncfNc',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('NCF afectado: $ncfAfectado'),
          pw.Text('Cliente: $nombreCliente'),
          pw.SizedBox(height: 8),
          pw.Text(
            'Monto: ${_money(monto)}',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          if (motivo != null && motivo.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text('Motivo: $motivo'),
          ],
          pw.SizedBox(height: 16),
          pw.Text(
            'Este documento anula o reduce el valor del comprobante referido.',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'NC_$ncfNc.pdf',
    );
  }

  /// Comprobante de entrega (despacho / delivery). Sin montos ni datos fiscales.
  static Future<void> imprimirComprobanteInterno(
    Venta v, {
    ConfiguracionEntity? empresa,
    bool compartir = false,
    String? telefonoCliente,
    String? whatsappCliente,
    String? direccionCliente,
  }) async {
    if (empresa != null) {
      _empresa = empresa;
      emisorNombre = (empresa.nombreComercial.isNotEmpty)
          ? empresa.nombreComercial
          : (empresa.razonSocial.isNotEmpty)
          ? empresa.razonSocial
          : 'Empresa';
      emisorRnc = empresa.rnc;
      emisorDir = empresa.direccion;
      emisorTel = empresa.telefono;
      emisorEmail = empresa.correo;
    }

    final tel = (telefonoCliente ?? v.clienteTelefono ?? '').trim();
    final wa = (whatsappCliente ?? v.clienteWhatsapp ?? '').trim();
    final dir = (direccionCliente ?? v.clienteDireccion ?? '').trim();
    final cot = v.numeroCotizacion;
    final ncf = (v.numeroFactura ?? '').trim();
    final cliente = (v.nombreCliente ?? 'Cliente #${v.clienteId}').trim();

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PrintFormats.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        build: (ctx) => [
          pw.Text(
            emisorNombre,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          if (emisorTel.isNotEmpty)
            pw.Text('Tel: $emisorTel', style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.Text(
              'COMPROBANTE DE ENTREGA',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Uso: despacho / delivery — no es comprobante fiscal',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Divider(),
          pw.Text(
            'Ref. cotización: $cot',
            style: const pw.TextStyle(fontSize: 10),
          ),
          if (ncf.isNotEmpty)
            pw.Text(
              'Ref. factura: $ncf',
              style: const pw.TextStyle(fontSize: 10),
            ),
          pw.Text(
            'Fecha: ${_fecha.format(v.fecha)}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'ENTREGAR A',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            cliente,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          if (tel.isNotEmpty)
            pw.Text('Teléfono: $tel', style: const pw.TextStyle(fontSize: 10)),
          if (wa.isNotEmpty)
            pw.Text('WhatsApp: $wa', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.Text(
            'Dirección de entrega:',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            dir.isNotEmpty
                ? dir
                : '(Sin dirección registrada — completar a mano)',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'ARTÍCULOS A ENTREGAR',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          _tablaEntrega(v.detalles),
          pw.SizedBox(height: 8),
          pw.Text(
            'Cantidad de líneas: ${v.detalles.length}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 28),
          pw.Text(
            'CONFIRMACIÓN DE ENTREGA',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Recibí conforme la mercancía descrita, en buen estado.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 36),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _bloqueFirmaEntrega(
                  'Firma del cliente',
                  'Nombre: _________________',
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Expanded(
                child: _bloqueFirmaEntrega(
                  'Firma quien entrega',
                  'Nombre: _________________',
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Fecha/hora entrega: ____ / ____ / ________   Hora: ____ : ____',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Observaciones: _______________________________________________',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '________________________________________________________________',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final name = ncf.isNotEmpty
        ? 'Entrega_${ncf}_$cot.pdf'
        : 'Entrega_$cot.pdf';
    if (compartir) {
      await Printing.sharePdf(bytes: bytes, filename: name);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
    }
  }

  static pw.Widget _tablaEntrega(List<DetalleVenta> detalles) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3.5),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _celdaEntrega('Descripción', bold: true),
            _celdaEntrega('Cant.', bold: true, align: pw.TextAlign.center),
            _celdaEntrega('Unidad', bold: true, align: pw.TextAlign.center),
          ],
        ),
        ...detalles.map((d) {
          final np = d.nombreProducto?.trim();
          final nombre = (np != null && np.isNotEmpty)
              ? np
              : 'Producto #${d.productoId}';
          return pw.TableRow(
            children: [
              _celdaEntrega(nombre),
              _celdaEntrega('${d.cantidad}', align: pw.TextAlign.center),
              _celdaEntrega('UND', align: pw.TextAlign.center),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _celdaEntrega(
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

  static pw.Widget _bloqueFirmaEntrega(String titulo, String lineaNombre) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          titulo,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 28),
        pw.Container(height: 0.8, color: PdfColors.black),
        pw.SizedBox(height: 4),
        pw.Text(lineaNombre, style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  static pw.Widget _ticketBody({
    required Venta v,
    required ConfiguracionEntity? empresa,
    required bool simple,
    required String ncf,
    required String titulo,
    required String cliente,
    String? rncCliente,
    String? direccionCliente,
    String? telefonoCliente,
    required String formaPago,
    required DateTime fecha,
    pw.MemoryImage? logoImage,

    String? codigoSeguridad,
    AmbienteDgii? ambienteDgii,
  }) {
    // —— Configuración documentos (editable en Configuración global) ——
    final showLogo = empresa?.docMostrarLogo ?? true;
    final showRnc = !simple && (empresa?.docMostrarRnc ?? true);
    final showDir = empresa?.docMostrarDireccion ?? true;
    final showTel = empresa?.docMostrarTelefono ?? true;
    final showMail = empresa?.docMostrarCorreo ?? true;
    final showCliente = empresa?.docMostrarCliente ?? true;
    final showNcf = !simple && (empresa?.docMostrarNcf ?? true);
    final showItbis = !simple && (empresa?.docMostrarItbisDesglose ?? true);
    final pie = (empresa?.docPiePagina ?? '').trim();

    final telEmp = (empresa?.telefono ?? emisorTel).trim();
    final mailEmp = (empresa?.correo ?? emisorEmail).trim();
    final dirEmp = (empresa?.direccion ?? emisorDir).trim();
    final nombreEmp = emisorNombre;
    final rncEmp = (empresa?.rnc ?? emisorRnc).trim();

    final cotizacion = v.numeroCotizacion;
    final fechaStr =
        '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year} '
        '${fecha.hour.toString().padLeft(2, '0')}:'
        '${fecha.minute.toString().padLeft(2, '0')}';
    final telCli = (telefonoCliente ?? v.clienteTelefono ?? '').trim();
    final dirCli = (direccionCliente ?? v.clienteDireccion ?? '').trim();
    final envio = v.costoEnvio;
    // Descuento general: montoDescuento o descuentoGlobal (el mayor / suma coherente)
    final descGlobal = v.montoDescuento > 0.001
        ? v.montoDescuento
        : v.descuentoGlobal;
    final descNombre = (v.descuentoNombre ?? '').trim();

    pw.Widget gap([double h = 3]) => pw.SizedBox(height: h);
    pw.Widget sep() => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Divider(thickness: 0.6, color: PdfColors.grey700),
    );
    pw.Widget center(String s, {double size = 8, bool bold = false}) =>
        pw.Center(
          child: pw.Text(
            s,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: size,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        );
    pw.Widget kv(String k, String val) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            k,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              val,
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
        ],
      ),
    );

    // Fila numérica: Cant | Precio | ITBIS | Importe (80 mm)
    pw.Widget nums(String a, String b, String c, String d, {bool header = false}) {
      final st = pw.TextStyle(
        fontSize: header ? 6.5 : 7.5,
        fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
      );
      return pw.Row(
        children: [
          pw.SizedBox(
            width: 28,
            child: pw.Text(a, style: st, textAlign: pw.TextAlign.left),
          ),
          pw.Expanded(
            child: pw.Text(b, style: st, textAlign: pw.TextAlign.right),
          ),
          pw.SizedBox(
            width: 48,
            child: pw.Text(c, style: st, textAlign: pw.TextAlign.right),
          ),
          pw.SizedBox(
            width: 52,
            child: pw.Text(d, style: st, textAlign: pw.TextAlign.right),
          ),
        ],
      );
    }

    final lineas = <pw.Widget>[];
    for (final d in v.detalles) {
      final desc = (d.nombreProducto ?? 'Ítem').trim();
      final cant = d.cantidad.toDouble();
      final precio = d.precioUnitario;
      final sub = d.subtotalLinea ?? d.subtotal;
      final kids = <pw.Widget>[
        pw.Text(
          desc,
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
      ];
      if ((d.ofertaNombre ?? '').trim().isNotEmpty) {
        kids.add(
          pw.Text(
            'Oferta: ${d.ofertaNombre!.trim()}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
          ),
        );
      }
      if (d.precioOriginal != null && d.precioOriginal! > precio + 0.001) {
        kids.add(
          pw.Text(
            'Antes: ${_money(d.precioOriginal!)}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        );
      }
      final itbisLinea = simple
          ? 0.0
          : sub * tasaComoFraccion(d.tasaImpuesto);
      kids.add(
        nums(
          cant == cant.roundToDouble()
              ? cant.toInt().toString()
              : cant.toStringAsFixed(2),
          _money(precio),
          simple ? '—' : _money(itbisLinea),
          _money(sub),
        ),
      );
      if (d.montoDescuento > 0.001) {
        kids.add(
          pw.Text(
            'Desc. línea: -${_money(d.montoDescuento)}'
            '${d.descuentoPorcentaje > 0 ? ' (${d.descuentoPorcentaje.toStringAsFixed(1)}%)' : ''}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
          ),
        );
      } else if (d.descuentoPorcentaje > 0.001) {
        kids.add(
          pw.Text(
            'Desc. línea: ${d.descuentoPorcentaje.toStringAsFixed(1)}%',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
          ),
        );
      }
      lineas.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: kids,
          ),
        ),
      );
    }
    if (envio > 0.0001) {
      lineas.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                'ENVÍO / DELIVERY',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              nums('1', _money(envio), simple ? '—' : _money(0), _money(envio)),
            ],
          ),
        ),
      );
    }

    pw.Widget totalRow(String label, String value, {bool bold = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: bold ? 10 : 8,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: bold ? 10 : 8,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ],
          ),
        );

    final codigoVisible = (codigoSeguridad ?? '').split('|').first.trim();
    final ambienteQr = ambienteDgii;
    final urlQr = (codigoVisible.isEmpty || ambienteQr == null)
        ? null
        : CodigoSeguridadEcf.urlConsulta(
            ambiente: ambienteQr,
            rncEmisor: rncEmp,
            rncComprador: (rncCliente ?? '').trim(),
            encf: ncf,
            codigoSeguridad: codigoSeguridad ?? '',
            montoTotal: v.montoTotal,
            fechaEmision:
                '${fecha.day.toString().padLeft(2, '0')}-'
                '${fecha.month.toString().padLeft(2, '0')}-'
                '${fecha.year}',
            resumenConsumo:
                ncf.toUpperCase().startsWith('E32') && v.montoTotal < 250000,
          );
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (showLogo && logoImage != null) ...[
          pw.Center(
            child: pw.Image(logoImage, height: 32, fit: pw.BoxFit.contain),
          ),
          gap(3),
        ],
        center(nombreEmp, size: 11, bold: true),
        if (showRnc && rncEmp.isNotEmpty) center('RNC: $rncEmp', size: 7),
        if (showTel && telEmp.isNotEmpty) center(telEmp, size: 8),
        if (showMail && mailEmp.isNotEmpty) center(mailEmp, size: 7),
        if (showDir && dirEmp.isNotEmpty) center(dirEmp, size: 7),
        sep(),
        // Tipo de comprobante (posición DGII: identificar el documento arriba)
        if (!simple && titulo.isNotEmpty) ...[
          center(titulo, size: 9, bold: true),
          gap(2),
        ],
        if (ncf.isNotEmpty && showNcf)
          kv(ncf.startsWith('E') ? 'e-NCF:' : 'NCF:', ncf),
        kv('Fecha:', fechaStr),
        kv('Forma Pago:', formaPago.toUpperCase()),
        if (cotizacion.isNotEmpty) kv('Cotización:', cotizacion),
        sep(),
        if (showCliente) ...[
          pw.Text(
            'Cliente',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(cliente, style: const pw.TextStyle(fontSize: 9)),
          if (telCli.isNotEmpty)
            pw.Text(telCli, style: const pw.TextStyle(fontSize: 8)),
          if (dirCli.isNotEmpty)
            pw.Text(dirCli, style: const pw.TextStyle(fontSize: 8)),
          if (showNcf && (rncCliente ?? '').trim().isNotEmpty)
            kv('RNC cliente:', rncCliente!.trim()),
          gap(4),
        ],
        sep(),
        pw.Text(
          'Descripción',
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
        nums('Cant.', 'Precio', 'ITBIS', 'Importe', header: true),
        gap(3),
        ...lineas,
        sep(),
        totalRow('Subtotal', _money(v.montoSubtotal)),
        if (descGlobal > 0.001)
          totalRow(
            descNombre.isNotEmpty ? 'Desc. $descNombre' : 'Descuento',
            '- ${_money(descGlobal)}',
          ),
        if (showItbis)
          totalRow(
            simple
                ? 'Impuesto'
                : etiquetaItbisLineas(v.detalles.map((d) => d.tasaImpuesto)),
            '+ ${_money(v.itbis)}',
          ),
        if (envio > 0.0001) totalRow('Envío', _money(envio)),
        gap(2),
        totalRow('TOTAL', _money(v.montoTotal), bold: true),
        if (ncf.startsWith('E')) ...[
          center('COMPROBANTE ELECTRONICO', size: 8, bold: true),
          center('Representacion impresa del e-CF.', size: 6),
          center('Consulte este comprobante en la DGII.', size: 6),
          if (codigoVisible.isNotEmpty) ...[
            kv('Codigo:', codigoVisible),
            if (urlQr != null)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: urlQr,
                    width: 90,
                    height: 90,
                  ),
                ),
              ),
          ] else
            center(
              'El codigo de seguridad va en la representacion con QR.',
              size: 6,
            ),
        ],
        sep(),
        if (pie.isNotEmpty)
          center(pie, size: 7)
        else ...[
          center('Verifique su pedido al recibirlo.', size: 6),
          center('Reclamaciones: 24 horas.', size: 6),
        ],
        gap(4),
        center('FiscoGest RD', size: 6),
      ],
    );
  }
}
