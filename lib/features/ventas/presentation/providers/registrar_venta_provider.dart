import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';

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
    this.total = 0.0,
    this.usuarioId,
    this.descuentoId,
    this.descuentoNombre,
    this.montoDescuento = 0.0,
  });
  final int? clienteId;
  final String? clienteNombre;
  final String tipoPago;
  final bool esCredito;
  final List<DetalleVenta> detalles;
  final double subtotal;
  final double itbis;
  final double total;
  final int? usuarioId;
  final int? descuentoId;
  final String? descuentoNombre;
  final double montoDescuento;
  RegistrarVentaState copyWith({
    int? clienteId,
    String? clienteNombre,
    String? tipoPago,
    bool? esCredito,
    List<DetalleVenta>? detalles,
    double? subtotal,
    double? itbis,
    double? total,
    int? usuarioId,
    int? descuentoId,
    String? descuentoNombre,
    double? montoDescuento,
  }) {
    return RegistrarVentaState(
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      tipoPago: tipoPago ?? this.tipoPago,
      esCredito: esCredito ?? this.esCredito,
      detalles: detalles ?? this.detalles,
      subtotal: subtotal ?? this.subtotal,
      itbis: itbis ?? this.itbis,
      total: total ?? this.total,
      usuarioId: usuarioId ?? this.usuarioId,
      descuentoId: descuentoId ?? this.descuentoId,
      descuentoNombre: descuentoNombre ?? this.descuentoNombre,
      montoDescuento: montoDescuento ?? this.montoDescuento,
    );
  }
}

class RegistrarVentaNotifier extends Notifier<RegistrarVentaState> {
  @override
  RegistrarVentaState build() {
    return const RegistrarVentaState();
  }

  void seleccionarCliente(int id, String nombre) {
    state = state.copyWith(clienteId: id, clienteNombre: nombre);
  }

  void cambiarFormaPago(String tipo) {
    final tipoNormalizado = tipo.toLowerCase().trim();
    final credito = tipoNormalizado == 'credito';
    state = state.copyWith(tipoPago: tipoNormalizado, esCredito: credito);
  }

  double? _obtenerStock(DetalleVenta linea) => linea.subtotalLinea;
  String? validarStockAlAgregar(DetalleVenta producto, double cantidad) {
    final stockDisponible = _obtenerStock(producto);
    if (stockDisponible == null || stockDisponible <= 0) {
      return 'Sin existencias en inventario';
    }
    if (cantidad > stockDisponible) {
      return 'Existencias insuficientes. Disponible: $stockDisponible';
    }
    return null;
  }

  String? agregarProducto(DetalleVenta linea) {
    final errorStock = validarStockAlAgregar(linea, linea.cantidad.toDouble());
    if (errorStock != null) return errorStock;
    final nuevaLista = List<DetalleVenta>.from(state.detalles)..add(linea);
    _recalcularTotales(nuevaLista);
    return null;
  }

  void quitarProducto(int indice) {
    final nuevaLista = List<DetalleVenta>.from(state.detalles)
      ..removeAt(indice);
    _recalcularTotales(nuevaLista);
  }

  void eliminarProducto(int indice) {
    quitarProducto(indice);
  }

  void cambiarCantidad(int indice, double cantidad) {
    if (cantidad < 1) cantidad = 1;
    final linea = state.detalles[indice];
    final errorStock = validarStockAlAgregar(linea, cantidad);
    if (errorStock != null) return;
    final listaActualizada = List<DetalleVenta>.from(state.detalles);
    final nuevoSubtotal = linea.precioUnitario * cantidad;
    listaActualizada[indice] = linea.copyWith(
      cantidad: cantidad.toInt(),
      subtotal: nuevoSubtotal,
      subtotalLinea: nuevoSubtotal,
    );
    _recalcularTotales(listaActualizada);
  }

  void aplicarDescuentoLinea(
    int indice,
    double valor, [
    bool esPorcentaje = true,
  ]) {
    final lista = List<DetalleVenta>.from(state.detalles);
    final linea = lista[indice];
    final descuento = esPorcentaje ? linea.subtotal * (valor / 100.0) : valor;
    final nuevoSubtotal = linea.subtotal - descuento;
    lista[indice] = linea.copyWith(subtotal: nuevoSubtotal);
    _recalcularTotales(lista);
  }

  void aplicarDescuentoManual(double monto) {
    state = state.copyWith(montoDescuento: monto);
    _recalcularTotales(state.detalles);
  }

  void quitarDescuento() {
    state = state.copyWith(
      montoDescuento: 0.0,
      descuentoId: null,
      descuentoNombre: null,
    );
    _recalcularTotales(state.detalles);
  }

  void seleccionarDescuento(int? id, String nombre, double monto) {
    state = state.copyWith(
      descuentoId: id ?? 0,
      descuentoNombre: nombre,
      montoDescuento: monto,
    );
    _recalcularTotales(state.detalles);
  }

  void _recalcularTotales(List<DetalleVenta> lineas) {
    const tasaItbis = 0.18;
    final subtotal = lineas.fold<double>(0.0, (sum, l) => sum + l.subtotal);
    final itbis = subtotal * tasaItbis;
    final total = subtotal + itbis - state.montoDescuento;
    state = state.copyWith(
      detalles: lineas,
      subtotal: subtotal,
      itbis: itbis,
      total: total,
    );
  }

  bool validarAntesDeGuardar() {
    if (state.clienteId == null ||
        (state.clienteNombre?.trim().isEmpty ?? true)) {
      return false;
    }
    final formasValidas = {
      'efectivo',
      'tarjeta',
      'credito',
      'transferencia',
      'cheque',
    };
    if (!formasValidas.contains(state.tipoPago.toLowerCase())) {
      return false;
    }
    if (state.detalles.isEmpty) {
      return false;
    }
    if (state.total <= 0) {
      return false;
    }
    for (var linea in state.detalles) {
      final stock = _obtenerStock(linea);
      if (stock == null || stock <= 0) return false;
    }
    return true;
  }

  void aplicarDescuentoGlobal(double monto) {
    state = state.copyWith(montoDescuento: monto);
    _recalcularTotales(state.detalles);
  }

  void vaciarVenta() {
    state = const RegistrarVentaState();
  }
}

final registrarVentaProvider =
    NotifierProvider<RegistrarVentaNotifier, RegistrarVentaState>(
      RegistrarVentaNotifier.new,
    );
