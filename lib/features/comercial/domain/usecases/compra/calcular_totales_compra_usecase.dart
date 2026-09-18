import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
/// Caso de uso: Cálculo automático de totales por línea y generales de compra.
///
/// Aplica la lógica fiscal:
/// - Subtotal por línea → cantidad × costo unitario − descuento
/// - Base imponible → monto sobre el que se calcula impuesto
/// - ITBIS por línea → base × tasa (18% estándar RD)
/// - Gastos asociados → flete + seguro + aranceles + otros gastos (por cantidad)
/// - Total por línea → base + ITBIS + gastos asociados
/// - Totales generales → suma de todas las líneas
class CalcularTotalesCompraUseCase {
  const CalcularTotalesCompraUseCase();
  static const double tasaItbis = 0.18;

  /// Recibe una línea de detalle y devuelve la línea con todos los importes calculados.
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

  /// Recibe un listado de líneas y devuelve todo calculado.
  List<DetalleCompra> calcularTodasLasLineas(List<DetalleCompra> lineas) {
    return lineas.map(calcularLinea).toList();
  }

  /// Calcula los totales generales a partir de líneas ya calculadas.
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

/// Resultado de los totales consolidados de una compra.
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
