import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/existencia.dart';
import '../services/existencia_service.dart';

// Servicio
final existenciaServiceProvider = Provider<ExistenciaService>((ref) {
  return ExistenciaService();
});

// Obtener todo el inventario
final todosLosInventariosProvider = FutureProvider<List<Existencia>>((ref) async {
  final servicio = ref.watch(existenciaServiceProvider);
  return await servicio.obtenerTodosActivos();
});

// Estado del inventario
class ExistenciaNotifier extends StateNotifier<AsyncValue<List<Existencia>>> {
  final ExistenciaService _servicio;

  ExistenciaNotifier(this._servicio) : super(const AsyncValue.loading()) {
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final lista = await _servicio.obtenerTodosActivos();
      state = AsyncValue.data(lista);
    } catch (error, pila) {
      state = AsyncValue.error(error, pila);
    }
  }

  Future<void> guardar(Existencia existencia) async {
    if (existencia.id == null) {
      await _servicio.crear(existencia);
    } else {
      await _servicio.actualizar(existencia);
    }
    await _cargar();
  }

  Future<void> borrar(int id) async {
    await _servicio.eliminar(id);
    await _cargar();
  }
}

final existenciaNotifierProvider = StateNotifierProvider<ExistenciaNotifier, AsyncValue<List<Existencia>>>((ref) {
  return ExistenciaNotifier(ref.watch(existenciaServiceProvider));
});