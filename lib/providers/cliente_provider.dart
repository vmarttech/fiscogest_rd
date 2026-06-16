import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cliente.dart';
import '../services/cliente_service.dart';

// ✅ Proveedor del Servicio: Instancia única de la lógica de datos
final clienteServiceProvider = Provider<ClienteService>((ref) => ClienteService());

// ✅ Proveedor de Lista General (para consultas simples si se necesita)
final todosLosClientesProvider = FutureProvider<List<Cliente>>((ref) async {
  return await ref.watch(clienteServiceProvider).obtenerTodos();
});

// ✅ NOTIFICADOR: Controla el estado, carga, guarda y elimina
class ClienteNotifier extends StateNotifier<AsyncValue<List<Cliente>>> {
  final ClienteService _servicio;

  // Iniciamos en estado de carga y ejecutamos la carga inicial
  ClienteNotifier(this._servicio) : super(const AsyncValue.loading()) {
    _cargarDatos();
  }

  /// 🔄 Carga o recarga la lista completa desde la base de datos
  Future<void> _cargarDatos() async {
    try {
      final lista = await _servicio.obtenerTodos();
      // Actualizamos el estado con los datos nuevos
      state = AsyncValue.data(lista);
    } catch (error, pilaError) {
      // En caso de fallo, guardamos el error para mostrarlo en pantalla
      state = AsyncValue.error(error, pilaError);
    }
  }

  /// 💾 Guarda un cliente (nuevo o edición) y refresca la lista
  Future<void> guardar(Cliente cliente) async {
    // Indicamos que estamos procesando
    state = const AsyncValue.loading();
    try {
      await _servicio.guardar(cliente);
      // Recargamos después de guardar
      await _cargarDatos();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // Permite capturar el error en la interfaz si es necesario
    }
  }

  // 🗑️ ELIMINAR: Nombre unificado y funcional (antes te faltaba o se llamaba distinto)
  Future<void> eliminar(int id) async {
    state = const AsyncValue.loading();
    try {
      await _servicio.eliminar(id);
      await _cargarDatos();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  // 🔄 Método público para recargar manualmente si lo necesitas
  Future<void> recargar() async {
    await _cargarDatos();
  }
}

// ✅ PROVEEDOR PRINCIPAL: Aquí se conecta todo el sistema
final clienteNotifierProvider = StateNotifierProvider<ClienteNotifier, AsyncValue<List<Cliente>>>((ref) {
  return ClienteNotifier(ref.watch(clienteServiceProvider));
});