import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
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

/// ============================================================
/// FASE 2 — GESTIÓN DE ESTADO: Registrar Venta
/// ============================================================

class RegistrarVentaState {

  const RegistrarVentaState({
    required this.numero,
    this.clienteId,
    this.tipoPago = '',
    this.esCredito = false,
    this.detalles = const [],
    this.subtotal = 0.0,
    this.itbis = 0.0,
    this.total = 0.0,
    this.usuarioId,
  });
  final String numero;
  final int? clienteId;
  final String tipoPago;
  final bool esCredito;
  final List<DetalleVenta> detalles;
  final double subtotal;
  final double itbis;
  final double total;
  final int? usuarioId;

  RegistrarVentaState copiarCon({
    String? numero,
    int? clienteId,
    String? tipoPago,
    bool? esCredito,
    List<DetalleVenta>? detalles,
    double? subtotal,
    double? itbis,
    double? total,
    int? usuarioId,
  }) {
    return RegistrarVentaState(
      numero: numero ?? this.numero,
      clienteId: clienteId ?? this.clienteId,
      tipoPago: tipoPago ?? this.tipoPago,
      esCredito: esCredito ?? this.esCredito,
      detalles: detalles ?? this.detalles,
      subtotal: subtotal ?? this.subtotal,
      itbis: itbis ?? this.itbis,
      total: total ?? this.total,
      usuarioId: usuarioId ?? this.usuarioId,
    );
  }
}

class RegistrarVentaNotifier extends StateNotifier<RegistrarVentaState> {
  RegistrarVentaNotifier()
      : super(RegistrarVentaState(
          numero: DateTime.now().millisecondsSinceEpoch.toString().substring(8),
        ));

  void seleccionarCliente(int? idCliente) {
    state = state.copiarCon(clienteId: idCliente);
  }

  void cambiarFormaPago(String formaPago, bool credito) {
    state = state.copiarCon(tipoPago: formaPago, esCredito: credito);
  }

  void agregarProducto(DetalleVenta linea) {
    final nuevaLista = List<DetalleVenta>.from(state.detalles)..add(linea);
    final subtotal = nuevaLista.fold<double>(0.0, (s, l) => s + l.subtotalLinea);
    final itbis = subtotal * 0.16;
    final total = subtotal + itbis;
    state = state.copiarCon(
      detalles: nuevaLista,
      subtotal: subtotal,
      itbis: itbis,
      total: total,
    );
  }

  void quitarProducto(int indice) {
    if (indice < 0 || indice >= state.detalles.length) return;
    final nuevaLista = List<DetalleVenta>.from(state.detalles)..removeAt(indice);
    final subtotal = nuevaLista.fold<double>(0.0, (s, l) => s + l.subtotalLinea);
    final itbis = subtotal * 0.16;
    final total = subtotal + itbis;
    state = state.copiarCon(
      detalles: nuevaLista,
      subtotal: subtotal,
      itbis: itbis,
      total: total,
    );
  }

  void asignarUsuarioDesdeSesion(int idUsuario) {
    state = state.copiarCon(usuarioId: idUsuario);
  }

  bool validarAntesDeGuardar() {
    return state.clienteId != null &&
        state.tipoPago.isNotEmpty &&
        state.detalles.isNotEmpty &&
        state.usuarioId != null &&
        state.total > 0;
  }
}

final registrarVentaProvider =
    StateNotifierProvider<RegistrarVentaNotifier, RegistrarVentaState>((ref) {
  return RegistrarVentaNotifier();
});
