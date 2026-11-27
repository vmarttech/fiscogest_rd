/// Prestaciones laborales RD (orientativo — Código de Trabajo).
///
/// Incluye: preaviso, auxilio de cesantía, vacaciones proporcionales
/// y regalía pascual proporcional.
///
/// No sustituye asesoría legal ni el cálculo formal del Ministerio de Trabajo.
class CalculadoraPrestacionesRd {
  CalculadoraPrestacionesRd._();

  /// Salario diario ordinario (mes comercial 23.83 días CT art. aprox. uso 23.83).
  static const double diasMesComercial = 23.83;

  static double salarioDiario(double salarioMensual) {
    if (salarioMensual <= 0) return 0;
    return _r2(salarioMensual / diasMesComercial);
  }

  /// Años y fracción de servicio entre ingreso y salida.
  static double aniosServicio(DateTime ingreso, DateTime salida) {
    final a = DateTime(ingreso.year, ingreso.month, ingreso.day);
    final b = DateTime(salida.year, salida.month, salida.day);
    if (b.isBefore(a)) return 0;
    final days = b.difference(a).inDays;
    return days / 365.25;
  }

  static int mesesCompletos(DateTime ingreso, DateTime salida) {
    final a = DateTime(ingreso.year, ingreso.month, ingreso.day);
    final b = DateTime(salida.year, salida.month, salida.day);
    if (b.isBefore(a)) return 0;
    var months = (b.year - a.year) * 12 + (b.month - a.month);
    if (b.day < a.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  /// Preaviso (días de salario) — art. 76 CT (empleador).
  /// 3–6 m: 7 · 6 m–1 a: 14 · ≥1 a: 28. Menos de 3 meses: 0.
  static int diasPreaviso(double anios) {
    final meses = anios * 12;
    if (meses < 3) return 0;
    if (meses < 6) return 7;
    if (meses < 12) return 14;
    return 28;
  }

  /// Auxilio de cesantía (días de salario) — art. 80 CT.
  /// 3–6 m: 6 · 6 m–1 a: 13 · 1–5 a: 21/año · ≥5 a: 23/año.
  static double diasCesantia(double anios) {
    final meses = anios * 12;
    if (meses < 3) return 0;
    if (meses < 6) return 6;
    if (meses < 12) return 13;
    if (anios < 5) {
      return _r2(21 * anios);
    }
    // 5 años exactos a tarifa 21; exceso a 23
    return _r2(21 * 5 + 23 * (anios - 5));
  }

  /// Vacaciones proporcionales (días hábiles orientativos).
  /// ≥5 años: 18 días/año · resto con ≥1 año: 14 · fracción del último periodo.
  static double diasVacaciones(double anios) {
    if (anios <= 0) return 0;
    final porAnio = anios >= 5 ? 18.0 : 14.0;
    // Proporcional a años (incluye fracción)
    if (anios < 1) {
      // Antes de 1 año: proporcional a 14 días
      return _r2(14 * anios);
    }
    return _r2(porAnio * anios);
  }

  /// Regalía pascual proporcional (Ley 16-97): 1 mes / 12 × meses trabajados
  /// del año calendario de la salida (tope 1 mes).
  static double regaliaPascual({
    required double salarioMensual,
    required DateTime fechaSalida,
    required DateTime fechaIngreso,
  }) {
    if (salarioMensual <= 0) return 0;
    final inicioAnio = DateTime(fechaSalida.year, 1, 1);
    final desde = fechaIngreso.isAfter(inicioAnio) ? fechaIngreso : inicioAnio;
    if (fechaSalida.isBefore(desde)) return 0;
    final meses = mesesCompletos(desde, fechaSalida) + 1; // mes de salida cuenta
    final m = meses.clamp(0, 12);
    return _r2(salarioMensual * (m / 12.0));
  }

  static LiquidacionPrestaciones calcular({
    required double salarioMensual,
    required DateTime fechaIngreso,
    required DateTime fechaSalida,
    bool incluirPreaviso = true,
    bool incluirCesantia = true,
    bool incluirVacaciones = true,
    bool incluirRegalia = true,
  }) {
    final anios = aniosServicio(fechaIngreso, fechaSalida);
    final diario = salarioDiario(salarioMensual);

    final dPrev = incluirPreaviso ? diasPreaviso(anios) : 0;
    final dCes = incluirCesantia ? diasCesantia(anios) : 0.0;
    final dVac = incluirVacaciones ? diasVacaciones(anios) : 0.0;

    final monPreaviso = _r2(diario * dPrev);
    final monCesantia = _r2(diario * dCes);
    final monVacaciones = _r2(diario * dVac);
    final monRegalia = incluirRegalia
        ? regaliaPascual(
            salarioMensual: salarioMensual,
            fechaSalida: fechaSalida,
            fechaIngreso: fechaIngreso,
          )
        : 0.0;

    final total = _r2(monPreaviso + monCesantia + monVacaciones + monRegalia);

    return LiquidacionPrestaciones(
      fechaIngreso: fechaIngreso,
      fechaSalida: fechaSalida,
      aniosServicio: _r2(anios),
      mesesServicio: mesesCompletos(fechaIngreso, fechaSalida),
      salarioMensual: salarioMensual,
      salarioDiario: diario,
      diasPreaviso: dPrev,
      montoPreaviso: monPreaviso,
      diasCesantia: _r2(dCes),
      montoCesantia: monCesantia,
      diasVacaciones: _r2(dVac),
      montoVacaciones: monVacaciones,
      montoRegalia: monRegalia,
      total: total,
    );
  }

  static double _r2(double v) => double.parse(v.toStringAsFixed(2));
}

class LiquidacionPrestaciones {
  const LiquidacionPrestaciones({
    required this.fechaIngreso,
    required this.fechaSalida,
    required this.aniosServicio,
    required this.mesesServicio,
    required this.salarioMensual,
    required this.salarioDiario,
    required this.diasPreaviso,
    required this.montoPreaviso,
    required this.diasCesantia,
    required this.montoCesantia,
    required this.diasVacaciones,
    required this.montoVacaciones,
    required this.montoRegalia,
    required this.total,
  });

  final DateTime fechaIngreso;
  final DateTime fechaSalida;
  final double aniosServicio;
  final int mesesServicio;
  final double salarioMensual;
  final double salarioDiario;
  final int diasPreaviso;
  final double montoPreaviso;
  final double diasCesantia;
  final double montoCesantia;
  final double diasVacaciones;
  final double montoVacaciones;
  final double montoRegalia;
  final double total;
}
