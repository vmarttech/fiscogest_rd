import 'package:fiscogest_rd/features/ventas/domain/entities/lista_precios.dart';

abstract class IListaPreciosRepository {
  Future<ListaPrecios?> obtenerPorProductoId(String productoId);
  Future<void> guardar(ListaPrecios listaPrecios);
  Future<void> actualizarPrecioVenta(String productoId, double nuevoPrecio);
}
