import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/i_venta_inventario_service.dart';

class RegistrarVenta {
  RegistrarVenta(this._servicio);
  final IVentaInventarioService _servicio;

  Future<Venta> call(Venta venta) async {
    return await _servicio.registrarVentaConInventario(venta);
  }
}
