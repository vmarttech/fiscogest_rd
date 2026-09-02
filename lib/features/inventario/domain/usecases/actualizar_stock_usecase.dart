import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';
import 'package:fiscogest_rd/features/inventario/domain/services/i_inventario_service.dart';

class ActualizarStockUseCase {
  ActualizarStockUseCase(this.servicio);
  // ✅ Constructor PRIMERO
  final IInventarioService servicio;

  Future<void> ejecutar({
    required int productoId,
    required double cantidad,
    required TipoMovimiento tipo,
  }) async {
    if (tipo == TipoMovimiento.entrada) {
      await servicio.sumarStock(productoId, cantidad);
    } else {
      await servicio.restarStock(productoId, cantidad);
    }
  }
}
