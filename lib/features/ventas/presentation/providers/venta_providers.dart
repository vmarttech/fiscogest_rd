import 'package:riverpod/riverpod.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/registrar_venta.dart';
import 'package:fiscogest_rd/features/ventas/data/repositories/ventas_repository_impl.dart';

final ventasRepositoryProvider = Provider<VentasRepositoryImpl>((ref) {
  throw UnimplementedError('Inyectar dependencias del repositorio en el punto de arranque');
});

final registrarVentaUseCaseProvider = Provider<RegistrarVenta>((ref) {
  final repo = ref.watch(ventasRepositoryProvider);
  return RegistrarVenta(repo);
});

class RegistrarVentaState {

  const RegistrarVentaState({
    this.numero = '',
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
  RegistrarVentaNotifier() : super(const RegistrarVentaState());

  void seleccionarCliente(int idCliente) {
    state = state.copiarCon(clienteId: idCliente);
  }

  void cambiarFormaPago(String formaPago, bool credito) {
    state = state.copiarCon(tipoPago: formaPago, esCredito: credito);
  }

  void calcularTotales(List<DetalleVenta> lista) {
    double subtotal = 0.0;
    double itbis = 0.0;

    for (final linea in lista) {
      subtotal += linea.subtotalLinea;
      final tasaDecimal = linea.tasaImpuesto / 100;
      itbis += linea.subtotalLinea * tasaDecimal;
    }

    final total = subtotal + itbis;
    state = state.copiarCon(
      subtotal: subtotal,
      itbis: itbis,
      total: total,
    );
  }

  void agregarProducto(DetalleVenta linea) {
    final nuevaLista = List<DetalleVenta>.from(state.detalles)..add(linea);
    calcularTotales(nuevaLista);
    state = state.copiarCon(detalles: nuevaLista);
  }

  void quitarProducto(int indice) {
    if (indice < 0 || indice >= state.detalles.length) return;
    final nuevaLista = List<DetalleVenta>.from(state.detalles)..removeAt(indice);
    calcularTotales(nuevaLista);
    state = state.copiarCon(detalles: nuevaLista);
  }

  void vaciarVenta() {
    state = const RegistrarVentaState();
  }

  bool validarAntesDeGuardar() {
    return state.clienteId != null &&
        state.tipoPago.isNotEmpty &&
        state.detalles.isNotEmpty &&
        state.total > 0;
  }
}

final registrarVentaProvider =
    StateNotifierProvider<RegistrarVentaNotifier, RegistrarVentaState>(
  (ref) => RegistrarVentaNotifier(),
);







final listaVentasProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return [];
});

final listaCotizacionesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return [];
});

final listaApartadosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return [];
});
