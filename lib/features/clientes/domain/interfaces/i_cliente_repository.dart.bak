import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_entity.dart';

abstract class IClienteRepository {
  Future<List<ClienteEntity>> obtenerClientes();
  Future<ClienteEntity?> obtenerClientePorId(int id);
  Future<int> guardarCliente(ClienteEntity cliente);
  Future<bool> eliminarCliente(int id);
}