import 'package:fiscogest_rd/features/comercial/domain/entities/promocion.dart';

class LineaVenta {

  const LineaVenta({
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
  });
  final String productoId;
  final double cantidad;
  final double precioUnitario;

  double get subtotal => cantidad * precioUnitario;
}

class ValidarPromocion {
  bool ejecutar({
    required Promocion promocion,
    required List<LineaVenta> lineas,
    DateTime? fechaReferencia,
    String? categoriaCliente,
  }) {
    final fecha = fechaReferencia ?? DateTime.now();

    if (!promocion.estaVigente(fecha)) {
      return false;
    }

    if (!promocion.aplicaACategoriaCliente(categoriaCliente)) {
      return false;
    }

    final lineasAplicables = lineas
        .where((l) => promocion.aplicaAProducto(l.productoId))
        .toList();

    if (lineasAplicables.isEmpty) {
      return false;
    }

    final cantidadTotal = lineasAplicables.fold<double>(0.0, (sum, l) => sum + l.cantidad);
    final montoTotal = lineasAplicables.fold<double>(0.0, (sum, l) => sum + l.subtotal);

    if (promocion.minimoCantidad != null && cantidadTotal < promocion.minimoCantidad!) {
      return false;
    }

    if (promocion.minimoMonto != null && montoTotal < promocion.minimoMonto!) {
      return false;
    }

    return true;
  }
}
