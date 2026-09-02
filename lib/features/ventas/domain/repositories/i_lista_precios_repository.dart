import 'package:fiscogest_rd/features/ventas/domain/entities/lista_precios.dart';

abstract class IListaPreciosRepository {
  Future<ListaPrecios?> obtenerPorProductoId(int productoId);
  Future<void> guardar(ListaPrecios listaPrecios);
  Future<void> actualizarPrecioVenta(int productoId, double nuevoPrecio);
}
