/// Retenciones y aportes de nómina RD (orientativo 2026).
///
/// Trabajador: AFP 2.87 %, SFS 3.04 %.
/// Empleador: AFP 7.10 %, SFS 7.09 %, SRL 1.10 % (riesgo base),
///            Fondo Solidaridad 0.40 %, INFOTEP 1 %.
///
/// Topes cotizables (Res. 01-2025 TSS, desde feb-2026):
///   SRL RD$92,892 · SFS RD$232,230 · AFP RD$464,460.
/// ISR: escala anual DGII → renta neta anualizada / 12.
///
/// No sustituye asesoría formal TSS / DGII / IDOPPRIL.
class CalculadoraNominaRd {
  CalculadoraNominaRd._();

  // ── Trabajador ──────────────────────────────────────────────
  static const double tasaAfpTrab = 0.0287;
  static const double tasaSfsTrab = 0.0304;

  // ── Empleador ───────────────────────────────────────────────
  static const double tasaAfpPat = 0.0710;
  static const double tasaSfsPat = 0.0709;
  /// Riesgo I / base (ajustable por clasificación IDOPPRIL).
  static const double tasaSrlPat = 0.0110;
  static const double tasaFondoSolidaridad = 0.0040;
  static const double tasaInfotep = 0.0100;

  // ── Topes 2026 ──────────────────────────────────────────────
  static const double topeSrl = 92892.0;
  static const double topeSfs = 232230.0;
  static const double topeAfp = 464460.0;

  // ── ISR anual (escala orientativa 2026) ─────────────────────
  static const double isrExentoAnual = 416220.0;
  static const double isrTramo2Anual = 624329.0;
  static const double isrTramo3Anual = 867123.0;
  static const double isrCuotaFijaT2 = 31216.0;
  static const double isrCuotaFijaT3 = 79776.0;

  static double _base(double bruto, double tope) {
    if (bruto <= 0) return 0;
    return bruto > tope ? tope : bruto;
  }

  static double _r2(double v) => double.parse(v.toStringAsFixed(2));

  // ── Trabajador ──────────────────────────────────────────────
  static double afpTrabajador(double bruto) =>
      _r2(_base(bruto, topeAfp) * tasaAfpTrab);

  static double sfsTrabajador(double bruto) =>
      _r2(_base(bruto, topeSfs) * tasaSfsTrab);

  static double isrAnual(double rentaNetaAnual) {
    if (rentaNetaAnual <= isrExentoAnual) return 0;
    if (rentaNetaAnual <= isrTramo2Anual) {
      return (rentaNetaAnual - isrExentoAnual) * 0.15;
    }
    if (rentaNetaAnual <= isrTramo3Anual) {
      return isrCuotaFijaT2 + (rentaNetaAnual - isrTramo2Anual) * 0.20;
    }
    return isrCuotaFijaT3 + (rentaNetaAnual - isrTramo3Anual) * 0.25;
  }

  static double isrMensualDesdeRentaNeta(double rentaNetaMensual) {
    return _r2(isrAnual(rentaNetaMensual * 12.0) / 12.0);
  }

  // ── Empleador ───────────────────────────────────────────────
  static double afpPatronal(double bruto) =>
      _r2(_base(bruto, topeAfp) * tasaAfpPat);

  static double sfsPatronal(double bruto) =>
      _r2(_base(bruto, topeSfs) * tasaSfsPat);

  static double srlPatronal(double bruto) =>
      _r2(_base(bruto, topeSrl) * tasaSrlPat);

  static double fondoSolidaridad(double bruto) =>
      _r2(_base(bruto, topeAfp) * tasaFondoSolidaridad);

  static double infotep(double bruto) =>
      _r2((bruto < 0 ? 0.0 : bruto) * tasaInfotep);

  /// Cálculo completo de una línea de planilla.
  static ({
    double afp,
    double sfs,
    double isr,
    double neto,
    double rentaNeta,
    double afpPat,
    double sfsPat,
    double srlPat,
    double fondoSol,
    double infotep,
    double costoEmpleador,
  }) desdeBruto(double bruto) {
    final b = bruto < 0 ? 0.0 : bruto;
    final afp = afpTrabajador(b);
    final sfs = sfsTrabajador(b);
    final rentaNeta = _r2(b - afp - sfs);
    final isr = isrMensualDesdeRentaNeta(rentaNeta);
    final neto = _r2(b - afp - sfs - isr);

    final afpP = afpPatronal(b);
    final sfsP = sfsPatronal(b);
    final srlP = srlPatronal(b);
    final fondo = fondoSolidaridad(b);
    final info = infotep(b);
    final costo = _r2(b + afpP + sfsP + srlP + fondo + info);

    return (
      afp: afp,
      sfs: sfs,
      isr: isr,
      neto: neto,
      rentaNeta: rentaNeta,
      afpPat: afpP,
      sfsPat: sfsP,
      srlPat: srlP,
      fondoSol: fondo,
      infotep: info,
      costoEmpleador: costo,
    );
  }
}
