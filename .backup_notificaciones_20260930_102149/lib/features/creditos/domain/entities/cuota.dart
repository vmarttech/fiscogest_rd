/// Cada cuota individual dentro de un plan de pagos
class Cuota {
  const Cuota({
    this.id,
    required this.numeroCuota,
    required this.fechaVencimiento,
    required this.montoCapital,
    required this.montoInteres,
    required this.montoTotal,
    required this.saldoDespues,
    this.pagada = false,
    this.fechaPago,
  });

  final int? id;
  final int numeroCuota;
  final DateTime fechaVencimiento;
  final double montoCapital;
  final double montoInteres;
  final double montoTotal;
  final double saldoDespues;
  final bool pagada;
  final DateTime? fechaPago;

  Cuota copyWith({
    int? id,
    int? numeroCuota,
    DateTime? fechaVencimiento,
    double? montoCapital,
    double? montoInteres,
    double? montoTotal,
    double? saldoDespues,
    bool? pagada,
    DateTime? fechaPago,
  }) {
    return Cuota(
      id: id ?? this.id,
      numeroCuota: numeroCuota ?? this.numeroCuota,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      montoCapital: montoCapital ?? this.montoCapital,
      montoInteres: montoInteres ?? this.montoInteres,
      montoTotal: montoTotal ?? this.montoTotal,
      saldoDespues: saldoDespues ?? this.saldoDespues,
      pagada: pagada ?? this.pagada,
      fechaPago: fechaPago ?? this.fechaPago,
    );
  }
}
