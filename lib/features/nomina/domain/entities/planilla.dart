class Planilla {
  Planilla({
    this.id,
    required this.periodo,
    this.tipoPeriodo = 'mensual',
    required this.fechaInicio,
    required this.fechaFin,
    this.estado = 'borrador',
    this.totalBruto = 0,
    this.totalNeto = 0,
    this.totalTssTrab = 0,
    this.totalIsr = 0,
    this.totalCostoEmpleador = 0,
    this.fechaPago,
    this.notas,
    this.creadoEn,
    this.actualizadoEn,
    this.lineas = const [],
  });

  final int? id;
  final String periodo;
  final String tipoPeriodo;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String estado;
  final double totalBruto;
  final double totalNeto;
  final double totalTssTrab;
  final double totalIsr;
  final double totalCostoEmpleador;
  final DateTime? fechaPago;
  final String? notas;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;
  final List<PlanillaLinea> lineas;

  bool get esBorrador => estado == 'borrador';
  bool get esCerrada => estado == 'cerrada';
  bool get esPagada => estado == 'pagada';
  bool get sePuedeEditar => esBorrador;

  Planilla copyWith({
    int? id,
    String? periodo,
    String? tipoPeriodo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? estado,
    double? totalBruto,
    double? totalNeto,
    double? totalTssTrab,
    double? totalIsr,
    double? totalCostoEmpleador,
    DateTime? fechaPago,
    String? notas,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
    List<PlanillaLinea>? lineas,
  }) {
    return Planilla(
      id: id ?? this.id,
      periodo: periodo ?? this.periodo,
      tipoPeriodo: tipoPeriodo ?? this.tipoPeriodo,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      estado: estado ?? this.estado,
      totalBruto: totalBruto ?? this.totalBruto,
      totalNeto: totalNeto ?? this.totalNeto,
      totalTssTrab: totalTssTrab ?? this.totalTssTrab,
      totalIsr: totalIsr ?? this.totalIsr,
      totalCostoEmpleador: totalCostoEmpleador ?? this.totalCostoEmpleador,
      fechaPago: fechaPago ?? this.fechaPago,
      notas: notas ?? this.notas,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      lineas: lineas ?? this.lineas,
    );
  }
}

class PlanillaLinea {
  PlanillaLinea({
    this.id,
    required this.planillaId,
    required this.empleadoId,
    required this.nombreEmpleado,
    this.cargo,
    this.salarioBase = 0,
    this.montoBruto = 0,
    this.tssAfp = 0,
    this.tssSfs = 0,
    this.isr = 0,
    this.montoNeto = 0,
    this.afpPatronal = 0,
    this.sfsPatronal = 0,
    this.srlPatronal = 0,
    this.fondoSolidaridad = 0,
    this.infotep = 0,
    this.notas,
  });

  final int? id;
  final int planillaId;
  final int empleadoId;
  final String nombreEmpleado;
  final String? cargo;
  final double salarioBase;
  final double montoBruto;
  final double tssAfp;
  final double tssSfs;
  final double isr;
  final double montoNeto;
  final double afpPatronal;
  final double sfsPatronal;
  final double srlPatronal;
  final double fondoSolidaridad;
  final double infotep;
  final String? notas;

  double get totalDescuentos => tssAfp + tssSfs + isr;
  double get totalPatronal =>
      afpPatronal + sfsPatronal + srlPatronal + fondoSolidaridad + infotep;
  double get costoEmpleador => montoBruto + totalPatronal;

  PlanillaLinea copyWith({
    int? id,
    int? planillaId,
    int? empleadoId,
    String? nombreEmpleado,
    String? cargo,
    double? salarioBase,
    double? montoBruto,
    double? tssAfp,
    double? tssSfs,
    double? isr,
    double? montoNeto,
    double? afpPatronal,
    double? sfsPatronal,
    double? srlPatronal,
    double? fondoSolidaridad,
    double? infotep,
    String? notas,
  }) {
    return PlanillaLinea(
      id: id ?? this.id,
      planillaId: planillaId ?? this.planillaId,
      empleadoId: empleadoId ?? this.empleadoId,
      nombreEmpleado: nombreEmpleado ?? this.nombreEmpleado,
      cargo: cargo ?? this.cargo,
      salarioBase: salarioBase ?? this.salarioBase,
      montoBruto: montoBruto ?? this.montoBruto,
      tssAfp: tssAfp ?? this.tssAfp,
      tssSfs: tssSfs ?? this.tssSfs,
      isr: isr ?? this.isr,
      montoNeto: montoNeto ?? this.montoNeto,
      afpPatronal: afpPatronal ?? this.afpPatronal,
      sfsPatronal: sfsPatronal ?? this.sfsPatronal,
      srlPatronal: srlPatronal ?? this.srlPatronal,
      fondoSolidaridad: fondoSolidaridad ?? this.fondoSolidaridad,
      infotep: infotep ?? this.infotep,
      notas: notas ?? this.notas,
    );
  }
}
