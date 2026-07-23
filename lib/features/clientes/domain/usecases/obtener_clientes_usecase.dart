import '../entities/cliente_entity.dart';
import '../interfaces/i_cliente_repository.dart';

class ObtenerClientesUseCase {
  final IClienteRepository _repository;

  ObtenerClientesUseCase(this._repository);

  Future<int> call() async {
    final clientes = await _repository.obtenerClientes();
    return clientes.length;
  }

  Future<List<ClienteEntity>> ejecutar() {
    return _repository.obtenerClientes();
  }
}