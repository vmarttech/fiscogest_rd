import 'package:fiscogest_rd/features/ventas/domain/entities/lista_precios.dart';

class CalcularPrecioDesdeMargen {
  const CalcularPrecioDesdeMargen();

  double call({required double costo, required double margen}) {
    if (costo <= 0) return 0.0;
    if (margen < 0) return costo;
    return ListaPrecios.calcularPrecioDesdeMargen(costo, margen);
  }
}
