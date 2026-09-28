import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';

/// Comprobante fiscal impreso (B01 crédito fiscal · B02 consumidor final).
/// Estructura orientada a uso comercial en RD (DGII serie B).
class ComprobantePdf {
  // Datos del emisor: los asigna imprimirFactura() con la configuración guardada.
  static ConfiguracionEntity? _empresa;
  static String emisorNombre = 'FiscoGest RD';
  static String emisorRnc = '000000000';
  static String emisorDir = 'Santo Domingo, República Dominicana';
  static String emisorTel = '';
  static String emisorEmail = '';

  static final _moneyFmt = NumberFormat('#,##0.00', 'en_US');
  static String _money(double v) => 'RD\$ ${_moneyFmt.format(v)}';
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
  }) async {
    final ncf = (v.numeroFactura ?? '').trim();
    if (ncf.isEmpty) {
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
    );
    final bytes = await doc.save();
    if (compartir) {
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Factura_$ncf.pdf',
      );
    } else {
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'Factura_$ncf.pdf',
      );
    }
  }

  /// Bytes listos + nombre de archivo (para menú Imprimir / Enviar).
  static Future<({Uint8List bytes, String filename})> prepararFactura(
    Venta v, {
    ConfiguracionEntity? empresa,
  }) async {
    final ncf = (v.numeroFactura ?? '').trim();
    if (ncf.isEmpty) {
      throw StateError('Sin NCF: no se puede generar comprobante fiscal');
    }
    final doc = await _buildDocumento(v, empresa: empresa);
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
    );
  }

  /// Genera bytes del PDF (para guardar archivo o compartir).
  static Future<Uint8List> generarBytes(
    Venta v, {
    ConfiguracionEntity? empresa,
  }) async {
    final doc = await _buildDocumento(v, empresa: empresa);
    return doc.save();
  }

  static Future<pw.Document> _buildDocumento(Venta v, {ConfiguracionEntity? empresa, String? rncCliente, String? direccionCliente, String? telefonoCliente}) async {
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
    final esB01 = ncf.startsWith('B01');
    final esB02 = ncf.startsWith('B02');
    final titulo = esB01
        ? 'FACTURA DE CRÉDITO FISCAL'
        : esB02
            ? 'FACTURA PARA CONSUMIDOR FINAL'
            : 'COMPROBANTE FISCAL';
    final tipoLabel = esB01
        ? 'B01 · Crédito fiscal'
        : esB02
            ? 'B02 · Consumidor final'
            : ncf.length >= 3
                ? ncf.substring(0, 3)
                : ncf;

    final detalles = v.detalles;
    final subtotal = v.montoSubtotal;
    final itbis = v.itbis;
    final total = v.montoTotal;
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

    final doc = pw.Document(
      title: 'Factura $ncf',
      author: emisorNombre,
    );

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
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 40),
        header: (ctx) => _header(titulo: titulo, tipoLabel: tipoLabel, ncf: ncf, logo: logoImage),
        footer: (ctx) => _footer(ctx, ncf),
        build: (ctx) => [
          pw.SizedBox(height: 8),
          if (_empresa?.docMostrarCliente ?? true)
            _bloqueEmisorCliente(
              cliente: cliente,
              rncCliente: rncCliente,
              direccionCliente: direccionCliente,
              telefonoCliente: telefonoCliente,
              esB01: esB01,
              venta: v,
              fecha: fecha,
            ),
          pw.SizedBox(height: 16),
          _tablaProductos(detalles),
          pw.SizedBox(height: 12),
          _totales(
            subtotal: subtotal,
            itbis: itbis,
            total: total,
            formaPago: formaPago,
            costoEnvio: v.costoEnvio,
            montoDescuento: v.montoDescuento,
          ),
          pw.SizedBox(height: 20),
          _leyendaLegal(esB01: esB01, ncf: ncf),
        ],
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
                    style: const pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  if ((_empresa?.docMostrarRnc ?? true) && emisorRnc.isNotEmpty)
                    pw.Text('RNC: $emisorRnc', style: const pw.TextStyle(fontSize: 9)),
                  if ((_empresa?.docMostrarDireccion ?? true) && emisorDir.isNotEmpty)
                    pw.Text(emisorDir, style: const pw.TextStyle(fontSize: 9)),
                  if ((_empresa?.docMostrarTelefono ?? true) && emisorTel.isNotEmpty)
                    pw.Text('Tel: $emisorTel', style: const pw.TextStyle(fontSize: 9)),
                  if ((_empresa?.docMostrarCorreo ?? true) && emisorEmail.isNotEmpty)
                    pw.Text(emisorEmail, style: const pw.TextStyle(fontSize: 9)),
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
                    style: const pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(tipoLabel, style: const pw.TextStyle(fontSize: 8)),
                  pw.SizedBox(height: 6),
                  if ((_empresa?.modoSimplificado != true) && (_empresa?.docMostrarNcf ?? true)) ...[
                    pw.Text('NCF', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    pw.Text(
                      ncf,
                      style: const pw.TextStyle(
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
                  style: const pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  cliente,
                  style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                if ((direccionCliente ?? '').trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Dir: ${(direccionCliente ?? '').trim()}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
                if ((telefonoCliente ?? '').trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Tel: ${(telefonoCliente ?? '').trim()}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
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
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.orange700),
                  ),
                ] else ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Consumidor final · sin crédito fiscal',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
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
              style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
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
      headerStyle: const pw.TextStyle(
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
              if ((_empresa?.modoSimplificado != true) && (_empresa?.docMostrarItbisDesglose ?? true))
                pw.Text(
                  'ITBIS discriminado al 18%.',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
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
              if ((_empresa?.modoSimplificado != true) && (_empresa?.docMostrarItbisDesglose ?? true)) ...[
                _totalRow('Subtotal', _money(subtotal)),
                if (montoDescuento > 0.001)
                  _totalRow('Descuento', '- ${_money(montoDescuento)}'),
                if (costoEnvio > 0.001)
                  _totalRow('Envío / delivery', _money(costoEnvio)),
                _totalRow('ITBIS (18%)', _money(itbis)),
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
    final ncfTxt = ((_empresa?.modoSimplificado != true) && (_empresa?.docMostrarNcf ?? true)) ? 'NCF: $ncf · ' : '';
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
    final ncfAfectado =
        ncfOrigen ?? (ventaOriginal?.numeroFactura ?? '-');
    final nombreCliente =
        (cliente != null && cliente.isNotEmpty)
            ? cliente
            : (ventaOriginal?.nombreCliente ?? '-');
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 40),
        build: (ctx) => [
          pw.Text(
            'NOTA DE CRÉDITO',
            style: const pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'B04 · Ajuste sobre factura',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'NCF Nota de crédito: $ncfNc',
            style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('NCF afectado: $ncfAfectado'),
          pw.Text('Cliente: $nombreCliente'),
          pw.SizedBox(height: 8),
          pw.Text(
            'Monto: ${_money(monto)}',
            style: const pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
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
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        build: (ctx) => [
          pw.Text(
            emisorNombre,
            style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          if (emisorTel.isNotEmpty)
            pw.Text('Tel: $emisorTel', style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.Text(
              'COMPROBANTE DE ENTREGA',
              style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
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
          pw.Text('Ref. cotización: $cot', style: const pw.TextStyle(fontSize: 10)),
          if (ncf.isNotEmpty)
            pw.Text('Ref. factura: $ncf', style: const pw.TextStyle(fontSize: 10)),
          pw.Text(
            'Fecha: ${_fecha.format(v.fecha)}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'ENTREGAR A',
            style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            cliente,
            style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          if (tel.isNotEmpty)
            pw.Text('Teléfono: $tel', style: const pw.TextStyle(fontSize: 10)),
          if (wa.isNotEmpty)
            pw.Text('WhatsApp: $wa', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.Text(
            'Dirección de entrega:',
            style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
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
            style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
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
            style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
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
    final name =
        ncf.isNotEmpty ? 'Entrega_${ncf}_$cot.pdf' : 'Entrega_$cot.pdf';
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
          style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 28),
        pw.Container(height: 0.8, color: PdfColors.black),
        pw.SizedBox(height: 4),
        pw.Text(lineaNombre, style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }
}
