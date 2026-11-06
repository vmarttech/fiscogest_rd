import 'package:fiscogest_rd/features/comercial/domain/entities/promocion.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/promocion/validar_promocion.dart';

class ResultadoDescuento {
  const ResultadoDescuento({
    required this.montoDescuento,
    required this.tipoPromocionAplicada,
    this.nombrePromocion,
    this.promocionId,
    this.descuentosPorProducto = const {},
  });

  final double montoDescuento;
  final String tipoPromocionAplicada;
  final String? nombrePromocion;
  final int? promocionId;

  /// Descuento monetario asignado a cada producto elegible.
  final Map<int, double> descuentosPorProducto;
}

class AplicarPromocion {
  const AplicarPromocion();

  double _redondear(double valor) => double.parse(valor.toStringAsFixed(2));

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
        montoDescuento: 0,
        tipoPromocionAplicada: 'ninguna',
      );
    }

    final elegibles = lineas.where((linea) {
      return promocion.aplicaAProducto(
            linea.productoId,
            idCategoria: linea.categoriaId,
          ) &&
          linea.cantidad > 0 &&
          linea.precioUnitario > 0 &&
          linea.subtotal > 0;
    }).toList();

    if (elegibles.isEmpty) {
      return const ResultadoDescuento(
        montoDescuento: 0,
        tipoPromocionAplicada: 'ninguna',
      );
    }

    final descuentos = <int, double>{};

    switch (promocion.tipo) {
      case 'porcentaje':
      case 'combo':
        final porcentaje = promocion.valor.clamp(0.0, 100.0);
        for (final linea in elegibles) {
          descuentos[linea.productoId] = _redondear(
            linea.subtotal * porcentaje / 100,
          );
        }
        break;

      case 'lleve2Pague1':
        for (final linea in elegibles) {
          final unidadesGratis = (linea.cantidad / 2).floor();
          if (unidadesGratis > 0) {
            descuentos[linea.productoId] = _redondear(
              unidadesGratis * linea.precioUnitario,
            );
          }
        }
        break;

      case 'montoFijo':
        final subtotalElegible = elegibles.fold<double>(
          0,
          (total, linea) => total + linea.subtotal,
        );
        final descuentoObjetivo = _redondear(
          promocion.valor.clamp(0.0, subtotalElegible),
        );

        var asignado = 0.0;
        for (var i = 0; i < elegibles.length; i++) {
          final linea = elegibles[i];
          final esUltima = i == elegibles.length - 1;
          final parte = esUltima
              ? _redondear(descuentoObjetivo - asignado)
              : _redondear(
                  descuentoObjetivo * linea.subtotal / subtotalElegible,
                );
          final limitada = parte.clamp(0.0, linea.subtotal);
          descuentos[linea.productoId] = limitada;
          asignado += limitada;
        }
        break;

      default:
        break;
    }

    final descuentosFinales = <int, double>{};
    for (final linea in elegibles) {
      final monto = descuentos[linea.productoId] ?? 0;
      if (monto > 0) {
        descuentosFinales[linea.productoId] = _redondear(
          monto.clamp(0.0, linea.subtotal),
        );
      }
    }

    final total = _redondear(
      descuentosFinales.values.fold<double>(0, (a, b) => a + b),
    );

    return ResultadoDescuento(
      montoDescuento: total,
      tipoPromocionAplicada: total > 0 ? promocion.tipo : 'ninguna',
      nombrePromocion: total > 0 ? promocion.nombre : null,
      promocionId: total > 0 ? promocion.id : null,
      descuentosPorProducto: descuentosFinales,
    );
  }
}
