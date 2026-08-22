import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

abstract class IVentaInventarioService {
  Future<Venta> registrarVentaConInventario(Venta venta);
}
