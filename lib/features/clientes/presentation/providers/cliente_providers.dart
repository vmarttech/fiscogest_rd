import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/clientes/data/dao/cliente_dao.dart';
import 'package:fiscogest_rd/features/clientes/data/repositories/cliente_repository_impl.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_entity.dart';
import 'package:fiscogest_rd/features/clientes/domain/interfaces/i_cliente_repository.dart';
import 'package:fiscogest_rd/features/clientes/domain/usecases/guardar_cliente_usecase.dart';
import 'package:fiscogest_rd/features/clientes/domain/usecases/obtener_clientes_usecase.dart';

/// Proveedor del DAO de Clientes
final clienteDaoProvider = Provider<ClienteDao>((ref) {
  final db = ref.watch(databaseProvider);
  return ClienteDao(db);
});

/// Proveedor del Repositorio de Clientes
final clienteRepositoryProvider = Provider<IClienteRepository>((ref) {
  final dao = ref.watch(clienteDaoProvider);
  return ClienteRepositoryImpl(dao);
});

/// Proveedor del Caso de Uso: Obtener Clientes
final obtenerClientesUseCaseProvider = Provider<ObtenerClientesUseCase>((ref) {
  final repository = ref.watch(clienteRepositoryProvider);
  return ObtenerClientesUseCase(repository);
});

/// Proveedor del Caso de Uso: Guardar Cliente
final guardarClienteUseCaseProvider = Provider<GuardarClienteUseCase>((ref) {
  final repository = ref.watch(clienteRepositoryProvider);
  return GuardarClienteUseCase(repository);
});

/// Notifier Provider para gestionar el estado reactivo de la lista de clientes
final clientesControllerProvider = AsyncNotifierProvider<ClientesController, List<ClienteEntity>>(() {
  return ClientesController();
});

class ClientesController extends AsyncNotifier<List<ClienteEntity>> {
  @override
  Future<List<ClienteEntity>> build() async {
    return _cargarClientes();
  }

  Future<List<ClienteEntity>> _cargarClientes() async {
    final obtenerClientes = ref.read(obtenerClientesUseCaseProvider);
    return await obtenerClientes.ejecutar();
  }

  Future<void> registrarCliente(ClienteEntity cliente) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final guardarUseCase = ref.read(guardarClienteUseCaseProvider);
      await guardarUseCase.ejecutar(cliente);
      return _cargarClientes();
    });
  }
}