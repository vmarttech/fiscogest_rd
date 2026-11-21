class CalcularMoraService {
  const CalcularMoraService();

  /// La configuración guarda MORA MENUAL (%); la mora diaria es mensual / 30.
  double tasaDiaria(double moraMensual) {
    if (moraMensual <= 0) return 0.0;
    return moraMensual / 30.0;
  }

  int diasVencidos(DateTime fecha, DateTime hoy, {bool pagada = false}) {
    if (pagada) return 0;
    final dias = hoy.difference(fecha).inDays;
    return dias < 0 ? 0 : dias;
  }

  double montoMora({
    required double saldo,
    required double moraMensual,
    required int dias,
  }) {
    if (saldo <= 0.001 || moraMensual <= 0 || dias <= 0) return 0.0;
    final valor = saldo * tasaDiaria(moraMensual) * dias;
    return double.parse(valor.toStringAsFixed(2));
  }
}
