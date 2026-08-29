import 'package:fiscogest_rd/features/ventas/domain/entities/lista_precios.dart';

class CalcularMargen {
  const CalcularMargen();

  double call({required double precioVenta, required double costo}) {
    return ListaPrecios.calcularMargen(precioVenta, costo);
  }
}
