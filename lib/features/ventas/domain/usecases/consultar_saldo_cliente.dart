import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';

class ConsultarSaldoCliente {
  ConsultarSaldoCliente(this._repository);

  final IVentasRepository _repository;

  Future<double> call(int clienteId) async {
    return await _repository.consultarSaldoCliente(clienteId);
  }
}
