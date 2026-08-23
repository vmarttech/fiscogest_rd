import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/dependency_injection/repository_injection.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/apartado.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';

final ventasRepositoryProvider = Provider<IVentasRepository>((ref) {
  return RepositoryInjection.instance.ventasRepository;
});

class RegistroVentaState {
  RegistroVentaState({
    this.numero = '',
    this.clienteId,
    this.clienteNombre = '',
    DateTime? fecha,
    this.vencimiento,
    this.detalles = const [],
    this.subtotal = 0.0,
    this.itbis = 0.0,
    this.descuento = 0.0,
    this.montoDescuento = 0.0,
    this.total = 0.0,
    this.tipoPago = 'efectivo',
    this.esCredito = false,
    this.usuarioId,
    this.descuentoId,
    this.descuentoNombre,
  }) : fecha = fecha ?? DateTime.now();

  final String numero;
  final int? clienteId;
  final String clienteNombre;
  final DateTime fecha;
  final DateTime? vencimiento;
  final List<dynamic> detalles;
  final double subtotal;
  final double itbis;
  final double descuento;
  final double montoDescuento;
  final double total;
  final String tipoPago;
  final bool esCredito;
  final int? usuarioId;
  final int? descuentoId;
  final String? descuentoNombre;

  RegistroVentaState copiar({
    String? numero,
    int? clienteId,
    String? clienteNombre,
    DateTime? fecha,
    DateTime? vencimiento,
    List<dynamic>? detalles,
    double? subtotal,
    double? itbis,
    double? descuento,
    double? montoDescuento,
    double? total,
    String? tipoPago,
    bool? esCredito,
    int? usuarioId,
    int? descuentoId,
    String? descuentoNombre,
  }) => RegistroVentaState(
    numero: numero ?? this.numero,
    clienteId: clienteId ?? this.clienteId,
    clienteNombre: clienteNombre ?? this.clienteNombre,
    fecha: fecha ?? this.fecha,
    vencimiento: vencimiento ?? this.vencimiento,
    detalles: detalles ?? this.detalles,
    subtotal: subtotal ?? this.subtotal,
    itbis: itbis ?? this.itbis,
    descuento: descuento ?? this.descuento,
    montoDescuento: montoDescuento ?? this.montoDescuento,
    total: total ?? this.total,
    tipoPago: tipoPago ?? this.tipoPago,
    esCredito: esCredito ?? this.esCredito,
    usuarioId: usuarioId ?? this.usuarioId,
    descuentoId: descuentoId ?? this.descuentoId,
    descuentoNombre: descuentoNombre ?? this.descuentoNombre,
  );
}

class RegistroVentaNotifier extends Notifier<RegistroVentaState> {
  @override
  RegistroVentaState build() => RegistroVentaState();

  void seleccionarCliente(int id, String nombre) {
    state = state.copiar(clienteId: id, clienteNombre: nombre);
  }

  void establecerVencimiento(DateTime fecha) {
    state = state.copiar(vencimiento: fecha);
  }

  void agregarProducto(dynamic linea) {
    final nuevas = List<dynamic>.from(state.detalles)..add(linea);
    state = state.copiar(detalles: nuevas);
    _recalcularTotales(nuevas);
  }

  void cambiarCantidad(int indice, double cantidad) {
    final nuevas = List<dynamic>.from(state.detalles);
    final actual = nuevas[indice] as DetalleVenta;
    final cantidadEntera = cantidad.round();
    final nuevoSubtotal = actual.precioUnitario * cantidad;
    nuevas[indice] = actual.copyWith(
      cantidad: cantidadEntera,
      subtotal: nuevoSubtotal,
      subtotalLinea: nuevoSubtotal,
    );
    _recalcularTotales(nuevas);
  }

  void quitarProducto(int indice) {
    final nuevas = List<dynamic>.from(state.detalles)..removeAt(indice);
    _recalcularTotales(nuevas);
  }

  void aplicarDescuento(double monto) {
    state = state.copiar(descuento: monto);
    _recalcularTotales(state.detalles);
  }

  void aplicarDescuentoLinea(int indice, double monto, bool esPorcentaje) {
    final nuevas = List<dynamic>.from(state.detalles);
    final actual = nuevas[indice] as DetalleVenta;
    nuevas[indice] = esPorcentaje
        ? actual.copyWith(descuentoPorcentaje: monto, montoDescuento: 0.0)
        : actual.copyWith(montoDescuento: monto, descuentoPorcentaje: 0.0);
    _recalcularTotales(nuevas);
  }

  void aplicarDescuentoManual(double montoFinal) {
    state = state.copiar(montoDescuento: montoFinal);
    _recalcularTotales(state.detalles);
  }

  void quitarDescuento() {
    state = state.copiar(descuento: 0.0, montoDescuento: 0.0);
    _recalcularTotales(state.detalles);
  }

  void establecerTipoPago(String tipo) {
    state = state.copiar(tipoPago: tipo);
  }

  void cambiarFormaPago(String tipo, bool credito) {
    state = state.copiar(tipoPago: tipo, esCredito: credito);
  }

  void seleccionarDescuento(int? id, String? nombre, double monto) {
    state = state.copiar(descuentoId: id, descuentoNombre: nombre, montoDescuento: monto);
    _recalcularTotales(state.detalles);
  }

  bool validarAntesDeGuardar() {
    return state.clienteId != null && state.detalles.isNotEmpty;
  }

  void vaciarVenta() {
    state = RegistroVentaState();
  }

  void vaciar() {
    state = RegistroVentaState();
  }

  void _recalcularTotales(List<dynamic> lineas) {
    double subtotal = 0.0;
    double descuentoLineas = 0.0;
    for (final linea in lineas) {
      if (linea is DetalleVenta) {
        subtotal += linea.subtotal;
        if (linea.descuentoPorcentaje > 0) {
          descuentoLineas += linea.subtotal * linea.descuentoPorcentaje / 100;
        } else if (linea.montoDescuento > 0) {
          descuentoLineas += linea.montoDescuento;
        }
      }
    }
    final baseGravable = (subtotal - descuentoLineas - state.montoDescuento).clamp(0.0, double.infinity);
    final itbis = baseGravable * 0.18;
    final total = baseGravable + itbis;
    state = state.copiar(
      subtotal: subtotal,
      itbis: itbis,
      descuento: descuentoLineas,
      total: total,
    );
  }
}

final registrarVentaProvider = NotifierProvider<RegistroVentaNotifier, RegistroVentaState>(RegistroVentaNotifier.new);

class CotizacionState {
  CotizacionState({
    this.numero = '',
    this.clienteId,
    this.clienteNombre = '',
    DateTime? fecha,
    this.vencimiento,
    this.detalles = const [],
    this.subtotal = 0.0,
    this.itbis = 0.0,
    this.descuento = 0.0,
    this.montoTotal = 0.0,
    this.descuentoId,
    this.descuentoNombre,
  }) : fecha = fecha ?? DateTime.now();

  final String numero;
  final int? clienteId;
  final String clienteNombre;
  final DateTime fecha;
  final DateTime? vencimiento;
  final List<dynamic> detalles;
  final double subtotal;
  final double itbis;
  final double descuento;
  final double montoTotal;
  final int? descuentoId;
  final String? descuentoNombre;

  CotizacionState copiar({
    String? numero,
    int? clienteId,
    String? clienteNombre,
    DateTime? fecha,
    DateTime? vencimiento,
    List<dynamic>? detalles,
    double? subtotal,
    double? itbis,
    double? descuento,
    double? montoTotal,
    int? descuentoId,
    String? descuentoNombre,
  }) => CotizacionState(
    numero: numero ?? this.numero,
    clienteId: clienteId ?? this.clienteId,
    clienteNombre: clienteNombre ?? this.clienteNombre,
    fecha: fecha ?? this.fecha,
    vencimiento: vencimiento ?? this.vencimiento,
    detalles: detalles ?? this.detalles,
    subtotal: subtotal ?? this.subtotal,
    itbis: itbis ?? this.itbis,
    descuento: descuento ?? this.descuento,
    montoTotal: montoTotal ?? this.montoTotal,
    descuentoId: descuentoId ?? this.descuentoId,
    descuentoNombre: descuentoNombre ?? this.descuentoNombre,
  );
}

class CotizacionNotifier extends Notifier<CotizacionState> {
  @override
  CotizacionState build() => CotizacionState();

  void seleccionarCliente(int id, String nombre) {
    state = state.copiar(clienteId: id, clienteNombre: nombre);
  }

  void establecerVencimiento(DateTime fecha) {
    state = state.copiar(vencimiento: fecha);
  }

  void aplicarDescuento(double valor) {
    state = state.copiar(descuento: valor);
  }

  void quitarDescuento() {}

  bool validarAntesDeGuardar() {
    return state.clienteId != null && state.detalles.isNotEmpty;
  }

  void vaciar() {
    state = CotizacionState();
  }
}

final cotizacionProvider = NotifierProvider<CotizacionNotifier, CotizacionState>(CotizacionNotifier.new);
final listaApartadosProvider = FutureProvider<List<Apartado>>((ref) async => []);
final listaCotizacionesProvider = FutureProvider<List<CotizacionState>>((ref) async => []);
final listaVentasProvider = FutureProvider<List<Venta>>((ref) async {
  final repo = ref.watch(ventasRepositoryProvider);
  return repo.listarVentas();
});
final ventaCargadaDesdeHistorialProvider = StateProvider<Venta?>((ref) => null);
final cargarVentaDesdeHistorialProvider = FutureProvider.family<void, int>((ref, ventaId) async {
  final repo = ref.watch(ventasRepositoryProvider);
  final venta = await repo.obtenerVentaPorId(ventaId);
  ref.read(ventaCargadaDesdeHistorialProvider.notifier).state = venta;
});
final ofertasActivosProvider = FutureProvider<List<dynamic>>((ref) async => []);
final descuentosActivosProvider = FutureProvider<List<dynamic>>((ref) async => []);

class RegistrarVentaUseCase {
  RegistrarVentaUseCase(this.repositorio);
  final IVentasRepository repositorio;
  Future<int> ejecutar(RegistroVentaState estado) async => 0;
}

final registrarVentaUseCaseProvider = Provider<RegistrarVentaUseCase>((ref) {
  final repo = ref.watch(ventasRepositoryProvider);
  return RegistrarVentaUseCase(repo);
});
