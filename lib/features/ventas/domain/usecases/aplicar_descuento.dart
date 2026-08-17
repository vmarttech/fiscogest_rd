import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';

class AplicarDescuento {

  AplicarDescuento(this._repository);
  final IVentasRepository _repository;

  Future<bool> call(String ventaId, String descuentoId) async {
    return await _repository.aplicarDescuento(ventaId, descuentoId);
  }
}
