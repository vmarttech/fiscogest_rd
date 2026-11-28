import 'package:fiscogest_rd/core/contabilidad/domain/enums/estado_periodo.dart';

class PeriodoFiscal {
  const PeriodoFiscal({
    this.id = 0,
    required this.codigo,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    required this.paisCodigo,
    required this.creadoEn,
    this.actualizadoEn,
  });

  final int id;
  final String codigo;
  final String nombre;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final EstadoPeriodo estado;
  final String paisCodigo;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  bool contiene(DateTime fecha) {
    final d = DateTime(fecha.year, fecha.month, fecha.day);
    final a = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
    final b = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);
    return !d.isBefore(a) && !d.isAfter(b);
  }

  bool get permiteAsientos => estado.permiteAsientos && !fechaFin.isBefore(fechaInicio);
}
