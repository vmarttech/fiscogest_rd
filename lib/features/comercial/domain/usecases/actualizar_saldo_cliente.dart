import 'package:fiscogest_rd/features/clientes/domain/interfaces/i_cliente_repository.dart';

class ActualizarSaldoCliente {
  ActualizarSaldoCliente(this._repositorio);
  final IClienteRepository _repositorio;

  Future<void> call({
    required int clienteId,
    required double monto,
    required bool esCargo,
  }) async {
    await _repositorio.actualizarSaldo(clienteId, monto, esCargo);
  }
}
