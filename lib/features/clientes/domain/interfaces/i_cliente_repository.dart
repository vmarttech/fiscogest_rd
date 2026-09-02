import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_entity.dart';

/// Contrato abstracto para el repositorio de Clientes.
///
/// Define operaciones disponibles sobre la entidad Cliente,
/// sin exponer detalles de almacenamiento ni tecnología.
abstract class IClienteRepository {
  Future<List<ClienteEntity>> obtenerClientes();
  Future<ClienteEntity?> obtenerClientePorId(int id);
  Future<int> guardarCliente(ClienteEntity cliente);
  Future<bool> eliminarCliente(int id);
  Future<void> actualizarSaldo(int clienteId, double monto, bool esCargo);
  Future<double?> obtenerSaldo(int clienteId);
}
