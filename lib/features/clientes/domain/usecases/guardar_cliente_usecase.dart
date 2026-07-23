import '../entities/cliente_entity.dart';
import '../interfaces/i_cliente_repository.dart';

class GuardarClienteUseCase {
  final IClienteRepository _repository;

  GuardarClienteUseCase(this._repository);

  Future<int> ejecutar(ClienteEntity cliente) {
    // Aquí se pueden aplicar validaciones de negocio estrictas antes de persistir
    if (cliente.nombre.trim().isEmpty) {
      throw ArgumentError('El nombre del cliente no puede estar vacío');
    }
    return _repository.guardarCliente(cliente);
  }
}