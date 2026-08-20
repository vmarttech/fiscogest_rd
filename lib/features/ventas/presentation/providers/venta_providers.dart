import 'package:riverpod/riverpod.dart';
import 'package:fiscogest_rd/core/dependency_injection/repository_injection.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/oferta.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/registrar_venta.dart';
import 'package:fiscogest_rd/features/ventas/data/repositories/ventas_repository_impl.dart';

final ventasRepositoryProvider = Provider<VentasRepositoryImpl>((ref) {
  return RepositoryInjection.instance.ventasRepository;
});

final registrarVentaUseCaseProvider = Provider<RegistrarVenta>((ref) {
  final repo = ref.watch(ventasRepositoryProvider);
  return RegistrarVenta(repo);
});

final descuentosActivosProvider = FutureProvider<List<Descuento>>((ref) async {
  final repo = ref.watch(ventasRepositoryProvider);
  return repo.obtenerDescuentosActivos();
});

final ofertasActivosProvider = FutureProvider<List<Oferta>>((ref) async {
  final repo = ref.watch(ventasRepositoryProvider);
  return repo.obtenerOfertasActivas();
});

// ✅ PROVIDERS QUE FALTABAN Y YA USABAN OTRAS PÁGINAS
final listaVentasProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(ventasRepositoryProvider);
  return repo.listarVentas();
});

final listaCotizacionesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(ventasRepositoryProvider);
  return repo.listarCotizaciones();
});

final listaApartadosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(ventasRepositoryProvider);
  return repo.listarApartados();
});

class RegistrarVentaState {
  const RegistrarVentaState({
    this.numero = '',
    this.clienteId,
    this.tipoPago = '',
    this.esCredito = false,
    this.detalles = const [],
    this.subtotal = 0.0,
    this.montoDescuento = 0.0,
    this.descuentoId,
    this.descuentoNombre,
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
  final double montoDescuento;
  final int? descuentoId;
  final String? descuentoNombre;
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
    double? montoDescuento,
    int? descuentoId,
    String? descuentoNombre,
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
      montoDescuento: montoDescuento ?? this.montoDescuento,
      descuentoId: descuentoId ?? this.descuentoId,
      descuentoNombre: descuentoNombre ?? this.descuentoNombre,
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

  void calcularTotales(List<DetalleVenta> lista, {Descuento? descuento}) {
    double subtotal = 0.0;
    double itbis = 0.0;

    for (final linea in lista) {
      subtotal += linea.subtotalLinea;
      final tasaDecimal = linea.tasaImpuesto / 100;
      itbis += linea.subtotalLinea * tasaDecimal;
    }

    double montoDescuento = 0.0;
    String? descuentoNombre;
    int? descuentoId;

    if (descuento != null) {
      descuentoId = descuento.id;
      descuentoNombre = descuento.nombre;

      if (descuento.tipo == 'porcentaje') {
        montoDescuento = subtotal * (descuento.valor / 100);
      } else if (descuento.tipo == 'monto') {
        montoDescuento = descuento.valor;
      }

      if (montoDescuento > subtotal) {
        montoDescuento = subtotal;
      }
    }

    final baseGravable = subtotal - montoDescuento;
    final total = baseGravable + itbis;

    state = state.copiarCon(
      subtotal: subtotal,
      montoDescuento: montoDescuento,
      descuentoId: descuentoId,
      descuentoNombre: descuentoNombre,
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

  void aplicarDescuento(Descuento descuento) {
    calcularTotales(state.detalles, descuento: descuento);
  }

  void quitarDescuento() {
    calcularTotales(state.detalles);
    state = state.copiarCon(
      descuentoId: null,
      descuentoNombre: null,
      montoDescuento: 0.0,
    );
  }

  void vaciarVenta() {
    state = const RegistrarVentaState();
  }

  bool validarAntesDeGuardar() {
    if (state.clienteId == null) return false;
    if (state.tipoPago.isEmpty) return false;
    if (state.detalles.isEmpty) return false;
    if (state.total <= 0) return false;
    return true;
  }
}

final registrarVentaProvider =
    StateNotifierProvider<RegistrarVentaNotifier, RegistrarVentaState>(
  (ref) => RegistrarVentaNotifier(),
);
