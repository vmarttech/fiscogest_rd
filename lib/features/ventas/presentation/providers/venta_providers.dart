import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/registrar_venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/actualizar_ventas_en_cascada.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/venta_orquestador_service.dart';
import 'package:fiscogest_rd/core/dependency_injection/repository_injection.dart';

/// Provider del Repositorio de Ventas — Usa instancia YA CONSTRUIDA
final ventasRepositoryProvider = Provider<IVentasRepository>((ref) {
  return RepositoryInjection.instance.ventasRepository;
});

/// Provider del Caso de Uso: Registrar Venta
final registrarVentaUseCaseProvider = Provider<RegistrarVenta>((ref) {
  final IVentasRepository repository = ref.watch(ventasRepositoryProvider);
  return RegistrarVenta(repository);
});

/// Provider del Caso de Uso: Actualizar Ventas en Cascada
final actualizarVentasEnCascadaUseCaseProvider = Provider<ActualizarVentasEnCascada>((ref) {
  final IVentasRepository repository = ref.watch(ventasRepositoryProvider);
  return ActualizarVentasEnCascada(repository);
});

/// Provider del Orquestador de Ventas
final ventaOrquestadorServiceProvider = Provider<VentaOrquestadorService>((ref) {
  final RegistrarVenta registrarVenta = ref.watch(registrarVentaUseCaseProvider);
  final ActualizarVentasEnCascada actualizarEnCascada = ref.watch(actualizarVentasEnCascadaUseCaseProvider);
  return VentaOrquestadorService(
    registrarVenta: registrarVenta,
    actualizarEnCascada: actualizarEnCascada,
  );
});

/// ============================================================
/// Historial de Ventas
/// ============================================================
final listaVentasProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final IVentasRepository repositorio = ref.watch(ventasRepositoryProvider);
  return repositorio.listarVentas();
});

/// ============================================================
/// Historial de Cotizaciones
/// ============================================================
final listaCotizacionesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final IVentasRepository repositorio = ref.watch(ventasRepositoryProvider);
  return repositorio.listarCotizaciones();
});

/// ============================================================
/// Historial de Apartados
/// ============================================================
final listaApartadosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final IVentasRepository repositorio = ref.watch(ventasRepositoryProvider);
  return repositorio.listarApartados();
});
