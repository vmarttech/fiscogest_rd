import 'package:fiscogest_rd/features/creditos/domain/entities/cuota.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/plan_pago.dart';

/// Servicio de cálculo financiero para créditos / fiao
/// Implementa el SISTEMA FRANCÉS de amortización:
///   - Cuota fija mensual
///   - Cada cuota = abono a capital + interés
///   - Interés se calcula sobre saldo pendiente
///
/// REGLAS:
///   - La TASA de interés es OCULTA al cliente
///   - El MONTO de interés SÍ se muestra al cliente
///   - Si tasa = 0 → cuotas iguales sin intereses
class CalculadoraCreditoService {
  const CalculadoraCreditoService._();

  /// Calcula la cuota fija mensual (sistema francés)
  /// [capital] = saldo financiado (total − abono inicial)
  /// [tasaMensual] = ej: 0.05 = 5% mensual
  /// [numeroCuotas] = cantidad de cuotas
  static double calcularCuotaFija({
    required double capital,
    required double tasaMensual,
    required int numeroCuotas,
  }) {
    if (capital <= 0) return 0.0;
    if (numeroCuotas <= 0) return capital;
    if (tasaMensual <= 0) return capital / numeroCuotas;

    final double factor = _potencia(1 + tasaMensual, numeroCuotas);
    return capital * tasaMensual * factor / (factor - 1);
  }

  /// Genera el plan de pagos completo con todas las cuotas detalladas
  static PlanPago generarPlanPago({
    required double capital,
    required double tasaMensual,
    required int numeroCuotas,
    required DateTime fechaPrimerVencimiento,
  }) {
    final List<Cuota> cuotas = [];
    double saldoPendiente = capital;
    final double cuotaFija = calcularCuotaFija(
      capital: capital,
      tasaMensual: tasaMensual,
      numeroCuotas: numeroCuotas,
    );

    for (int i = 1; i <= numeroCuotas; i++) {
      final double interes = saldoPendiente * tasaMensual;
      final double abonoCapital = cuotaFija - interes;
      final double montoTotal = abonoCapital + interes;

      // Última cuota: ajustar por redondeos
      double nuevoSaldo;
      double capitalFinal = abonoCapital;
      double totalFinal = montoTotal;

      if (i == numeroCuotas) {
        capitalFinal = saldoPendiente;
        totalFinal = capitalFinal + interes;
        nuevoSaldo = 0.0;
      } else {
        nuevoSaldo = saldoPendiente - abonoCapital;
      }

      final fechaVencimiento = DateTime(
        fechaPrimerVencimiento.year,
        fechaPrimerVencimiento.month + (i - 1),
        fechaPrimerVencimiento.day,
      );

      cuotas.add(Cuota(
        numeroCuota: i,
        fechaVencimiento: fechaVencimiento,
        montoCapital: _redondear(capitalFinal),
        montoInteres: _redondear(interes),
        montoTotal: _redondear(totalFinal),
        saldoDespues: _redondear(nuevoSaldo),
      ));

      saldoPendiente = nuevoSaldo;
    }

    return PlanPago(
      tasaInteresMensual: tasaMensual,
      numeroCuotas: numeroCuotas,
      montoPorCuota: _redondear(cuotaFija),
      fechaPrimerVencimiento: fechaPrimerVencimiento,
      cuotas: cuotas,
    );
  }

  /// Calcula el monto total de intereses del plan
  static double calcularTotalIntereses(PlanPago plan) {
    return plan.totalIntereses;
  }

  /// Calcula interés simple para un pago único (1 sola cuota)
  /// Útil cuando el cliente paga todo al final del plazo
  static double calcularInteresSimple({
    required double capital,
    required double tasaMensual,
    required int plazoDias,
  }) {
    if (capital <= 0 || tasaMensual <= 0 || plazoDias <= 0) return 0.0;
    final double tasaDiaria = tasaMensual / 30;
    return capital * tasaDiaria * plazoDias;
  }

  /// Genera un resumen visible para el cliente
  /// (NO incluye la tasa, solo montos finales)
  static ResumenCreditoCliente generarResumenCliente({
    required double totalVenta,
    required double abonoInicial,
    required double tasaMensual,
    required int numeroCuotas,
    required DateTime fechaPrimerVencimiento,
  }) {
    final double saldoFinanciado =
        (totalVenta - abonoInicial).clamp(0.0, double.infinity);

    if (numeroCuotas <= 1) {
      // Pago único
      const int plazoDias = 30; // default
      final double interes = calcularInteresSimple(
        capital: saldoFinanciado,
        tasaMensual: tasaMensual,
        plazoDias: plazoDias,
      );
      return ResumenCreditoCliente(
        totalVenta: _redondear(totalVenta),
        abonoInicial: _redondear(abonoInicial),
        saldoFinanciado: _redondear(saldoFinanciado),
        montoInteres: _redondear(interes),
        totalAPagar: _redondear(saldoFinanciado + interes),
        numeroCuotas: 1,
        montoPorCuota: _redondear(saldoFinanciado + interes),
        fechaPrimerVencimiento: fechaPrimerVencimiento,
        cuotas: [],
      );
    }

    final PlanPago plan = generarPlanPago(
      capital: saldoFinanciado,
      tasaMensual: tasaMensual,
      numeroCuotas: numeroCuotas,
      fechaPrimerVencimiento: fechaPrimerVencimiento,
    );

    return ResumenCreditoCliente(
      totalVenta: _redondear(totalVenta),
      abonoInicial: _redondear(abonoInicial),
      saldoFinanciado: _redondear(saldoFinanciado),
      montoInteres: _redondear(plan.totalIntereses),
      totalAPagar: _redondear(plan.totalAPagar),
      numeroCuotas: plan.numeroCuotas,
      montoPorCuota: _redondear(plan.montoPorCuota),
      fechaPrimerVencimiento: plan.fechaPrimerVencimiento,
      cuotas: plan.cuotas,
    );
  }

  // ============================================
  // MÉTODOS AUXILIARES
  // ============================================

  /// Potencia entera (evita dependencia de dart:math pow)
  static double _potencia(double base, int exponente) {
    double resultado = 1.0;
    for (int i = 0; i < exponente; i++) {
      resultado *= base;
    }
    return resultado;
  }

  /// Redondea a 2 decimales (moneda RD$)
  static double _redondear(double valor) {
    return (valor * 100).round() / 100;
  }
}

/// Resumen visible para el cliente — NO incluye tasa de interés
class ResumenCreditoCliente {
  const ResumenCreditoCliente({
    required this.totalVenta,
    required this.abonoInicial,
    required this.saldoFinanciado,
    required this.montoInteres,
    required this.totalAPagar,
    required this.numeroCuotas,
    required this.montoPorCuota,
    required this.fechaPrimerVencimiento,
    required this.cuotas,
  });

  final double totalVenta;
  final double abonoInicial;
  final double saldoFinanciado;
  final double montoInteres; // ✅ SÍ ve cuánto sube
  final double totalAPagar;
  final int numeroCuotas;
  final double montoPorCuota;
  final DateTime fechaPrimerVencimiento;
  final List<Cuota> cuotas; // Tabla completa para la hoja de cuotas

  /// Cuánto "sube" el crédito respecto al valor de los productos
  double get incrementoTotal {
    return montoInteres;
  }

  /// Porcentaje de incremento (solo para uso interno, NO mostrar a cliente)
  double get porcentajeIncremento {
    if (saldoFinanciado <= 0) return 0.0;
    return montoInteres / saldoFinanciado;
  }
}
