import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/impuestos/domain/services/resolver_tasa_itbis.dart';

/// Totales de compra. [tasaItbis] en 0 anula el impuesto (modo simplificado).
/// En modo fiscal cada linea conserva su tasaImpuestoLinea.
class CalcularTotalesCompraUseCase {
  const CalcularTotalesCompraUseCase({this.tasaItbis = 0.18});

  final double tasaItbis;

  DetalleCompra calcularLinea(DetalleCompra linea) {
    final importeBruto = linea.cantidad * linea.costoUnitario;
    final montoDescuento = importeBruto * (linea.descuentoPorcentaje / 100);
    final subtotalLinea = importeBruto - montoDescuento;
    final baseImponible = subtotalLinea;
    final tasa = tasaItbis <= 0
        ? 0.0
        : tasaComoFraccion(linea.tasaImpuestoLinea);
    final itbis = baseImponible * tasa;
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
      tasaImpuestoLinea: tasa,
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
    final tasas = {
      for (final linea in lineasCalculadas)
        (linea.tasaImpuestoLinea * 10000).round(),
    };
    final tasaDocumento = tasas.length == 1
        ? lineasCalculadas.first.tasaImpuestoLinea
        : tasaItbis;
    final totalCompra = lineasCalculadas.fold<double>(
      0.0,
      (sum, linea) => sum + linea.totalLinea,
    );
    return TotalesCompra(
      subtotalSinImpuestos: subtotalSinImpuestos,
      montoDescuentoGlobal: montoDescuentoGlobal,
      montoImpuesto: montoItbis,
      tasaImpuesto: tasaDocumento,
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
