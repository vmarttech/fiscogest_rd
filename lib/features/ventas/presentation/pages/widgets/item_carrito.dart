import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';

class ItemCarrito {

  ItemCarrito({required this.producto, required this.cantidad, required this.precio});
  final Producto producto;
  final double cantidad;
  final double precio;
}
