class KpiPeriodo {
  const KpiPeriodo({
    required this.ventas,
    required this.numFacturas,
    required this.ganancia,
    required this.ventasAnterior,
    required this.gananciaAnterior,
  });

  final double ventas;
  final int numFacturas;
  final double ganancia;
  final double ventasAnterior;
  final double gananciaAnterior;

  double get ticketPromedio => numFacturas == 0 ? 0.0 : ventas / numFacturas;

  double get margenPct => ventas <= 0 ? 0.0 : (ganancia / ventas) * 100.0;

  double get deltaVentasPct {
    if (ventasAnterior <= 0) return ventas > 0 ? 100.0 : 0.0;
    return ((ventas - ventasAnterior) / ventasAnterior) * 100.0;
  }

  double get deltaGananciaPct {
    if (gananciaAnterior <= 0) return ganancia > 0 ? 100.0 : 0.0;
    return ((ganancia - gananciaAnterior) / gananciaAnterior) * 100.0;
  }

  static const empty = KpiPeriodo(
    ventas: 0,
    numFacturas: 0,
    ganancia: 0,
    ventasAnterior: 0,
    gananciaAnterior: 0,
  );
}

class SeriePunto {
  const SeriePunto(this.label, this.valor, {this.fecha});
  final String label;
  final double valor;
  final DateTime? fecha;
}

class TopProducto {
  const TopProducto({
    required this.nombre,
    required this.cantidad,
    required this.monto,
  });
  final String nombre;
  final double cantidad;
  final double monto;
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.hoy,
    required this.semana,
    required this.mes,
    required this.anio,
    required this.serie30Dias,
    required this.porFormaPago,
    required this.topProductos,
  });

  final KpiPeriodo hoy;
  final KpiPeriodo semana;
  final KpiPeriodo mes;
  final KpiPeriodo anio;
  final List<SeriePunto> serie30Dias;
  final Map<String, double> porFormaPago;
  final List<TopProducto> topProductos;

  static const empty = DashboardSnapshot(
    hoy: KpiPeriodo.empty,
    semana: KpiPeriodo.empty,
    mes: KpiPeriodo.empty,
    anio: KpiPeriodo.empty,
    serie30Dias: [],
    porFormaPago: {},
    topProductos: [],
  );
}

enum PeriodoDash { hoy, semana, mes, anio }
