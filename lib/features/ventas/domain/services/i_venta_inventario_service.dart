import 'package:fiscogest_rd/features/ventas/domain/entities/resultado_venta_inventario.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';

abstract class IVentaInventarioService {
  Future<ResultadoVentaInventario> registrarVentaConInventario(Venta venta);

  /// Venta ya existente (p. ej. cotización facturada en Caja).
  /// Solo kardex + restarStock. No inserta venta.
  /// Devuelve costo de salida en centavos (0 si no hubo movimiento).
  Future<void> aplicarSalidaInventario(Venta venta);

  /// Nota de crédito: devuelve stock (kardex entrada + sumarStock).
  Future<void> aplicarEntradaInventarioPorNc(
    Venta venta, {
    required String ncfNc,
  });
}
