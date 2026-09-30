import 'package:riverpod/riverpod.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_completo.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/clientes/data/repositories/cliente_completo_repository.dart';

// ✅ PROVEEDOR: OBTIENE LA BASE ÚNICA Y LA PASA AL REPOSITORIO
final clienteCompletoRepositoryProvider = Provider<ClienteCompletoRepository>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return ClienteCompletoRepository(db);
});

final clienteCompletoControllerProvider =
    AsyncNotifierProvider<ClienteCompletoController, List<ClienteCompleto>>(() {
      return ClienteCompletoController();
    });

class ClienteCompletoController extends AsyncNotifier<List<ClienteCompleto>> {
  @override
  Future<List<ClienteCompleto>> build() async {
    final repositorio = ref.read(clienteCompletoRepositoryProvider);
    return await repositorio.obtenerClientes();
  }

  Future<List<ClienteCompleto>> buscarPorNombre(String nombre) async {
    final termino = nombre.toLowerCase().trim();
    final repositorio = ref.read(clienteCompletoRepositoryProvider);
    final listadoCompleto = await repositorio.obtenerClientes();
    if (termino.isEmpty) {
      return listadoCompleto;
    }
    return listadoCompleto
        .where(
          (cliente) =>
              cliente.nombre.toLowerCase().contains(termino) ||
              cliente.rncCedula.toLowerCase().contains(termino) ||
              cliente.telefono.toLowerCase().contains(termino),
        )
        .toList();
  }

  Future<void> guardar(ClienteCompleto cliente) async {
    final repositorio = ref.read(clienteCompletoRepositoryProvider);
    await repositorio.agregarCliente(cliente);
    ref.invalidateSelf();
  }

  Future<void> actualizar(ClienteCompleto cliente) async {
    final repositorio = ref.read(clienteCompletoRepositoryProvider);
    await repositorio.actualizarCliente(cliente);
    ref.invalidateSelf();
  }

  Future<void> eliminar(int identificador) async {
    final repositorio = ref.read(clienteCompletoRepositoryProvider);
    await repositorio.eliminarCliente(identificador);
    ref.invalidateSelf();
  }
}
