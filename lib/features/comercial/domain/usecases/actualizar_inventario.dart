import 'package:fiscogest_rd/features/inventario/domain/repositories/inventario_repository.dart';

class ActualizarInventario {
  ActualizarInventario(this._repositorio);
  final InventarioRepository _repositorio;

  Future<bool> call({
    required int idProducto,
    required double cantidad,
    required bool esEntrada,
  }) async {
    final stockActual = await _repositorio.obtenerStockActual(idProducto);
    if (stockActual == null) return false;

    final double stockNuevo = esEntrada
        ? stockActual + cantidad
        : stockActual - cantidad;

    if (stockNuevo < 0) return false;

    await _repositorio.actualizarStock(idProducto, stockNuevo);
    return true;
  }
}
