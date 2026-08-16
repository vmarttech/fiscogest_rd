import 'package:fiscogest_rd/features/comercial/domain/entities/promocion.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/promocion/validar_promocion.dart';

class ResultadoDescuento {

  const ResultadoDescuento({
    required this.montoDescuento,
    required this.tipoPromocionAplicada,
    this.nombrePromocion,
  });
  final double montoDescuento;
  final String tipoPromocionAplicada;
  final String? nombrePromocion;
}

class AplicarPromocion {
  const AplicarPromocion();

  ResultadoDescuento ejecutar({
    required Promocion promocion,
    required List<LineaVenta> lineas,
    String? categoriaCliente,
  }) {
    final validador = ValidarPromocion();
    final esValida = validador.ejecutar(
      promocion: promocion,
      lineas: lineas,
      categoriaCliente: categoriaCliente,
    );

    if (!esValida) {
      return const ResultadoDescuento(
        montoDescuento: 0.0,
        tipoPromocionAplicada: 'ninguna',
      );
    }

    final lineasAplicables = lineas
        .where((l) => promocion.aplicaAProducto(l.productoId))
        .toList();

    final subtotal = lineasAplicables.fold<double>(0.0, (sum, l) => sum + l.subtotal);
    double descuento = 0.0;

    switch (promocion.tipo) {
      case 'porcentaje':
        descuento = subtotal * (promocion.valor / 100.0);
        break;

      case 'montoFijo':
        descuento = promocion.valor;
        break;

      case 'lleve2Pague1':
        final cantidadTotal = lineasAplicables.fold<double>(0.0, (sum, l) => sum + l.cantidad);
        final unidadesGratis = (cantidadTotal / 2).floorToDouble();
        descuento = unidadesGratis * lineasAplicables.first.precioUnitario;
        break;

      case 'combo':
        descuento = subtotal * (promocion.valor / 100.0);
        break;

      default:
        descuento = 0.0;
    }

    return ResultadoDescuento(
      montoDescuento: descuento,
      tipoPromocionAplicada: promocion.tipo,
      nombrePromocion: promocion.nombre,
    );
  }
}
