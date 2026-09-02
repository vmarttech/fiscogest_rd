import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_entity.dart';
import 'package:fiscogest_rd/features/clientes/domain/interfaces/i_cliente_repository.dart';

class ObtenerClientesUseCase {
  ObtenerClientesUseCase(this._repository);
  final IClienteRepository _repository;

  Future<int> call() async {
    final clientes = await _repository.obtenerClientes();
    return clientes.length;
  }

  Future<List<ClienteEntity>> ejecutar() {
    return _repository.obtenerClientes();
  }
}
