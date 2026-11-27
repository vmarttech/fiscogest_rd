class LiquidacionHistorial {
  LiquidacionHistorial({
    this.id,
    required this.empleadoId,
    required this.nombreEmpleado,
    required this.fechaIngreso,
    required this.fechaSalida,
    required this.salarioMensual,
    required this.aniosServicio,
    this.montoPreaviso = 0,
    this.montoCesantia = 0,
    this.montoVacaciones = 0,
    this.montoRegalia = 0,
    this.total = 0,
    this.notas,
    this.creadoEn,
  });

  final int? id;
  final int empleadoId;
  final String nombreEmpleado;
  final DateTime fechaIngreso;
  final DateTime fechaSalida;
  final double salarioMensual;
  final double aniosServicio;
  final double montoPreaviso;
  final double montoCesantia;
  final double montoVacaciones;
  final double montoRegalia;
  final double total;
  final String? notas;
  final DateTime? creadoEn;
}
