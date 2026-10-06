import 'package:pdf/pdf.dart';

/// Formatos de impresión unificados para FiscoGest RD.
///
/// - [ticket80]: operación diaria (caja, abonos, cronograma, estado de cuenta).
/// - [a4]: contrato, solicitud/expediente, NC formal, e-CF formal.
class PrintFormats {
  PrintFormats._();

  static const double anchoTicketMm = 80;
  static const double margenTicketMm = 3;

  /// Ancho fijo 80 mm; el alto lo calcula cada documento.
  static const PdfPageFormat ticket80Base = PdfPageFormat.roll80;

  static PdfPageFormat ticket80({required double altoMm}) {
    const m = margenTicketMm * PdfPageFormat.mm;
    return PdfPageFormat(
      anchoTicketMm * PdfPageFormat.mm,
      altoMm * PdfPageFormat.mm,
      marginLeft: m,
      marginRight: m,
      marginTop: m,
      marginBottom: m,
    );
  }

  /// Estimación simple de alto (mm) a partir de “líneas” de ~42 chars.
  static double estimarAltoTicketMm({
    required int lineasEquivalentes,
    int itemsExtra = 0,
    double baseMm = 64,
  }) {
    return baseMm + lineasEquivalentes * 3.1 + itemsExtra * 1.5;
  }

  static final PdfPageFormat a4 = PdfPageFormat.a4.copyWith(
    marginLeft: 18 * PdfPageFormat.mm,
    marginRight: 18 * PdfPageFormat.mm,
    marginTop: 16 * PdfPageFormat.mm,
    marginBottom: 16 * PdfPageFormat.mm,
  );

  /// Alias explícito: letter → misma intención formal; preferir [a4].
  static final PdfPageFormat formal = a4;
}
