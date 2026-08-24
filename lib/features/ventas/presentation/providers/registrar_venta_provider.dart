import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
@immutable
class RegistrarVentaState {
  const RegistrarVentaState({
    this.clienteId,
    this.clienteNombre,
    this.tipoPago = 'efectivo',
    this.esCredito = false,
    this.detalles = const [],
    this.subtotal = 0.0,
    this.itbis = 0.0,
    this.descuento = 0.0,
    this.montoDescuento = 0.0,
    this.total = 0.0,
    this.usuarioId,
    this.descuentoId,
    this.descuentoNombre,
  });
  final int? clienteId;
  final String? clienteNombre;
  final String tipoPago;
  final bool esCredito;
  final List<dynamic> detalles;
  final double subtotal;
  final double itbis;
  final double descuento;
  final double montoDescuento;
  final double total;
  final int? usuarioId;
  final int? descuentoId;
  final String? descuentoNombre;
  RegistrarVentaState copyWith({
    int? clienteId,
    String? clienteNombre,
    String? tipoPago,
    bool? esCredito,
    List<dynamic>? detalles,
    double? subtotal,
    double? itbis,
    double? descuento,
    double? montoDescuento,
    double? total,
    int? usuarioId,
    int? descuentoId,
    String? descuentoNombre,
  }) {
    return RegistrarVentaState(
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      tipoPago: tipoPago ?? this.tipoPago,
      esCredito: esCredito ?? this.esCredito,
      detalles: detalles ?? this.detalles,
      subtotal: subtotal ?? this.subtotal,
      itbis: itbis ?? this.itbis,
      descuento: descuento ?? this.descuento,
      montoDescuento: montoDescuento ?? this.montoDescuento,
      total: total ?? this.total,
      usuarioId: usuarioId ?? this.usuarioId,
      descuentoId: descuentoId ?? this.descuentoId,
      descuentoNombre: descuentoNombre ?? this.descuentoNombre,
    );
  }
}
class RegistrarVentaNotifier extends StateNotifier<RegistrarVentaState> {
  RegistrarVentaNotifier() : super(const RegistrarVentaState());
  void seleccionarCliente(int id, String nombre) {
    state = state.copyWith(
      clienteId: id,
      clienteNombre: nombre,
    );
  }
  void cambiarFormaPago(String tipo, bool credito) {
    state = state.copyWith(
      tipoPago: tipo,
      esCredito: credito,
    );
  }
  void agregarProducto(dynamic linea) {
    final nuevaLista = List<dynamic>.from(state.detalles)..add(linea);
    _recalcularTotales(nuevaLista);
  }
  void cambiarCantidad(int indice, double nuevaCantidad) {
    final nuevaLista = List<dynamic>.from(state.detalles);
    if (indice >= 0 && indice < nuevaLista.length) {
      final linea = nuevaLista[indice];
      final precio = (linea.precioUnitario as num? ?? 0.0).toDouble();
      linea.cantidad = nuevaCantidad;
      linea.subtotal = precio * nuevaCantidad;
      nuevaLista[indice] = linea;
      _recalcularTotales(nuevaLista);
    }
  }
  void quitarProducto(int indice) {
    final nuevaLista = List<dynamic>.from(state.detalles);
    if (indice >= 0 && indice < nuevaLista.length) {
      nuevaLista.removeAt(indice);
      _recalcularTotales(nuevaLista);
    }
  }
  void aplicarDescuentoManual(double montoFinal) {
    final base = state.subtotal;
    final nuevoDescuento = base - montoFinal;
    final baseImponible = montoFinal / 1.18;
    final nuevoItbis = baseImponible * 0.18;
    state = state.copyWith(
      descuento: nuevoDescuento,
      montoDescuento: nuevoDescuento,
      itbis: nuevoItbis,
      total: montoFinal,
    );
  }
  void quitarDescuento() {
    final base = state.subtotal;
    const tasa = 0.18;
    final nuevoItbis = base * tasa;
    final nuevoTotal = base + nuevoItbis;
    state = state.copyWith(
      descuento: 0.0,
      montoDescuento: 0.0,
      itbis: nuevoItbis,
      total: nuevoTotal,
      descuentoId: null,
      descuentoNombre: null,
    );
  }
  void seleccionarDescuento(int? id, String? nombre, double valor) {
    final base = state.subtotal;
    final nuevoDescuento = valor;
    final baseImponible = base - nuevoDescuento;
    const tasa = 0.18;
    final nuevoItbis = baseImponible * tasa;
    final nuevoTotal = baseImponible + nuevoItbis;
    state = state.copyWith(
      descuento: nuevoDescuento,
      montoDescuento: nuevoDescuento,
      itbis: nuevoItbis,
      total: nuevoTotal,
      descuentoId: id,
      descuentoNombre: nombre,
    );
  }
  void aplicarDescuentoLinea(int indice, double valor, bool esPorcentaje) {
    final nuevaLista = List<dynamic>.from(state.detalles);
    if (indice >= 0 && indice < nuevaLista.length) {
      final linea = nuevaLista[indice];
      final precio = (linea.precioUnitario as num? ?? 0.0).toDouble();
      final cantidad = (linea.cantidad as num? ?? 1).toDouble();
      final subtotalSinDescuento = precio * cantidad;
      double montoDesc;
      if (esPorcentaje) {
        montoDesc = subtotalSinDescuento * (valor / 100.0);
      } else {
        montoDesc = valor;
      }
      linea.montoDescuento = montoDesc;
      linea.subtotal = subtotalSinDescuento - montoDesc;
      nuevaLista[indice] = linea;
    }
    _recalcularTotales(nuevaLista);
  }
  bool validarAntesDeGuardar() {
    if (state.clienteId == null || (state.clienteNombre?.trim().isEmpty ?? true)) {
      return false;
    }
    if (state.detalles.isEmpty) {
      return false;
    }
    if (state.total <= 0) {
      return false;
    }
    return true;
  }
  void vaciarVenta() {
    state = const RegistrarVentaState();
  }
  void _recalcularTotales(List<dynamic> detalles) {
    double subtotal = 0.0;
    double sumaDescuentos = 0.0;
    for (var d in detalles) {
      final valor = (d.subtotal as num? ?? 0.0).toDouble();
      final desc = (d.montoDescuento as num? ?? 0.0).toDouble();
      subtotal += valor + desc;
      sumaDescuentos += desc;
    }
    final baseImponible = subtotal - sumaDescuentos;
    const tasa = 0.18;
    final itbis = baseImponible * tasa;
    final total = baseImponible + itbis;
    state = state.copyWith(
      detalles: detalles,
      subtotal: subtotal,
      descuento: sumaDescuentos,
      montoDescuento: sumaDescuentos,
      itbis: itbis,
      total: total,
    );
  }
}
final registrarVentaProvider =
    StateNotifierProvider<RegistrarVentaNotifier, RegistrarVentaState>((ref) {
  return RegistrarVentaNotifier();
});
