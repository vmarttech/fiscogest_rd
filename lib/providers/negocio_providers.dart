import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogestrd/models/negocio.dart';
import 'package:fiscogestrd/services/negocio_service.dart';

// Proveedor del servicio (sin estado, solo acceso a métodos)
final negocioServiceProvider = Provider<NegocioService>((ref) {
  return NegocioService();
});

// Proveedor de estado: guarda y notifica los datos del negocio
final negocioProvider =
    StateNotifierProvider<NegocioNotifier, AsyncValue<Negocio?>>((ref) {
      return NegocioNotifier(ref.watch(negocioServiceProvider));
    });

class NegocioNotifier extends StateNotifier<AsyncValue<Negocio?>> {
  NegocioNotifier(this._servicio) : super(const AsyncValue.loading()) {
    // Al iniciar, cargamos los datos automáticamente
    _cargarDatos();
  }
  final NegocioService _servicio;

  Future<void> _cargarDatos() async {
    try {
      final datos = await _servicio.obtenerNegocio();
      state = AsyncValue.data(datos);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Acción: Guardar datos y actualizar estado
  Future<void> guardar(Negocio negocio) async {
    try {
      state = const AsyncValue.loading();
      await _servicio.guardarNegocio(negocio);
      // Recargar después de guardar
      final datosActualizados = await _servicio.obtenerNegocio();
      state = AsyncValue.data(datosActualizados);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
