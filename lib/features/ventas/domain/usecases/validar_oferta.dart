import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';

class ValidarOferta {
  ValidarOferta(this._repository);
  final IVentasRepository _repository;

  Future<bool> call(String ofertaId, double montoCompra) async {
    return await _repository.validarOferta(int.parse(ofertaId), montoCompra);
  }
}
