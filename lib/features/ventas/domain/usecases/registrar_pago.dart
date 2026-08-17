import 'package:fiscogest_rd/features/ventas/domain/entities/pago.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';

class RegistrarPago {

  RegistrarPago(this._repository);
  final IVentasRepository _repository;

  Future<Pago> call(Pago pago) async {
    return await _repository.registrarPago(pago);
  }
}
