import 'package:fiscogest_rd/features/ventas/domain/entities/lista_precios.dart';

class ValidarPrecioVenta {
  const ValidarPrecioVenta();

  bool call({required double precioVenta, double? precioMinimo}) {
    return ListaPrecios(
      productoId: 0,
      precioVenta: precioVenta,
      precioMinimo: precioMinimo,
    ).precioVentaEsValido();
  }
}
