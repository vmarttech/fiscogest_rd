import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';

/// Totales de compra. [tasaItbis] = 0.0 en modo simplificado; 0.18 en fiscal.
class CalcularTotalesCompraUseCase {
  const CalcularTotalesCompraUseCase({this.tasaItbis = 0.18});

  final double tasaItbis;

  DetalleCompra calcularLinea(DetalleCompra linea) {
    final importeBruto = linea.cantidad * linea.costoUnitario;
    final montoDescuento = importeBruto * (linea.descuentoPorcentaje / 100);
    final subtotalLinea = importeBruto - montoDescuento;
    final baseImponible = subtotalLinea;
    final itbis = baseImponible * tasaItbis;
    final gastosAsociados =
        (linea.fleteUnitario * linea.cantidad) +
        (linea.seguroUnitario * linea.cantidad) +
        (linea.arancelesUnitario * linea.cantidad) +
        (linea.gastosUnitario * linea.cantidad);
    final totalLinea = baseImponible + itbis + gastosAsociados;
    return linea.copyWith(
      montoDescuentoLinea: montoDescuento,
      subtotalLinea: subtotalLinea,
      baseImponibleLinea: baseImponible,
      tasaImpuestoLinea: tasaItbis,
      itbisLinea: itbis,
      totalLinea: totalLinea,
    );
  }

  List<DetalleCompra> calcularTodasLasLineas(List<DetalleCompra> lineas) {
    return lineas.map(calcularLinea).toList();
  }

  TotalesCompra calcularTotalesGenerales(List<DetalleCompra> lineasCalculadas) {
    final subtotalSinImpuestos = lineasCalculadas.fold<double>(
      0.0,
      (sum, linea) => sum + linea.subtotalLinea,
    );
    final montoDescuentoGlobal = lineasCalculadas.fold<double>(
      0.0,
      (sum, linea) => sum + linea.montoDescuentoLinea,
    );
    final montoItbis = lineasCalculadas.fold<double>(
      0.0,
      (sum, linea) => sum + linea.itbisLinea,
    );
    final totalCompra = lineasCalculadas.fold<double>(
      0.0,
      (sum, linea) => sum + linea.totalLinea,
    );
    return TotalesCompra(
      subtotalSinImpuestos: subtotalSinImpuestos,
      montoDescuentoGlobal: montoDescuentoGlobal,
      montoImpuesto: montoItbis,
      tasaImpuesto: tasaItbis,
      totalCompra: totalCompra,
    );
  }
}

class TotalesCompra {
  const TotalesCompra({
    required this.subtotalSinImpuestos,
    required this.montoDescuentoGlobal,
    required this.montoImpuesto,
    required this.tasaImpuesto,
    required this.totalCompra,
  });

  final double subtotalSinImpuestos;
  final double montoDescuentoGlobal;
  final double montoImpuesto;
  final double tasaImpuesto;
  final double totalCompra;
}
