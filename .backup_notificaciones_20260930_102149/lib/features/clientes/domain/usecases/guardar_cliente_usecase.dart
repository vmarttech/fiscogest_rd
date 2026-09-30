import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_entity.dart';
import 'package:fiscogest_rd/features/clientes/domain/interfaces/i_cliente_repository.dart';

class GuardarClienteUseCase {
  GuardarClienteUseCase(this._repository);
  final IClienteRepository _repository;

  Future<int> ejecutar(ClienteEntity cliente) {
    // Aquí se pueden aplicar validaciones de negocio estrictas antes de persistir
    if (cliente.nombre.trim().isEmpty) {
      throw ArgumentError('El nombre del cliente no puede estar vacío');
    }
    return _repository.guardarCliente(cliente);
  }
}
