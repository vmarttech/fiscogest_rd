/// Reglas de capacidad de pago / límite de cuota mensual.
class CapacidadPagoService {
  /// Porcentaje por defecto si no hay parámetro configurado (30%).
  static const double porcentajeDefault = 0.30;

  /// Límite de cuota sugerido = ingreso × porcentaje (ej. 10 000 × 0.30 = 3 000).
  static double limiteCuotaSugerido({
    required double ingresoMensual,
    double porcentaje = porcentajeDefault,
  }) {
    if (ingresoMensual <= 0) return 0;
    final p = porcentaje <= 0 ? porcentajeDefault : porcentaje;
    // Si viene como 30 en vez de 0.30
    final frac = p > 1 ? p / 100.0 : p;
    return ingresoMensual * frac;
  }

  /// true si la cuota del plan no excede el límite aprobado.
  static bool cuotaDentroDelLimite({
    required double montoCuota,
    required double limiteCuotaMensual,
  }) {
    if (limiteCuotaMensual <= 0) return true; // sin límite definido → no bloquea
    return montoCuota <= limiteCuotaMensual + 0.01;
  }

  /// Mensaje de rechazo para UI.
  static String mensajeExcede({
    required double montoCuota,
    required double limiteCuotaMensual,
    required double ingresoMensual,
  }) {
    return 'La cuota (${montoCuota.toStringAsFixed(2)}) supera el límite '
        'de cuota del cliente (${limiteCuotaMensual.toStringAsFixed(2)}). '
        'Capacidad sugerida: 30% de ingresos'
        '${ingresoMensual > 0 ? ' (${ingresoMensual.toStringAsFixed(2)})' : ''}. '
        'Ajuste el plan o el límite en el cliente.';
  }
}
