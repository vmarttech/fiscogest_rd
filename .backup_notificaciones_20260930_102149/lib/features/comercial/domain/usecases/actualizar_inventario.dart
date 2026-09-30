import 'package:fiscogest_rd/features/comercial/domain/repositories/i_inventario_repository.dart';

class ActualizarInventario {
  ActualizarInventario(this._repositorio);
  final IInventarioRepository _repositorio;

  Future<bool> call({
    required int idProducto,
    required double cantidad,
    required bool esEntrada,
  }) async {
    if (esEntrada) {
      await _repositorio.aumentarExistencias(
        productoId: idProducto,
        cantidad: cantidad,
      );
    } else {
      await _repositorio.descontarExistencias(
        productoId: idProducto,
        cantidad: cantidad,
      );
    }
    return true;
  }
}
