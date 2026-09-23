import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

abstract class IVentaInventarioService {
  Future<Venta> registrarVentaConInventario(Venta venta);

  /// Venta ya existente (p. ej. cotización facturada en Caja).
  /// Solo kardex + restarStock. No inserta venta.
  Future<void> aplicarSalidaInventario(Venta venta);
}
