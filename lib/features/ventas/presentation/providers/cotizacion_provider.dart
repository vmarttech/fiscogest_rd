import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
@immutable
class CotizacionState {
  const CotizacionState({
    required this.numero,
    required this.fecha,
    this.vencimiento,
    this.clienteId,
    this.clienteNombre,
    required this.subtotal,
    required this.itbis,
    required this.descuento,
    required this.montoDescuento,
    required this.montoTotal,
    this.descuentoId,
    this.descuentoNombre,
  });
  final String numero;
  final DateTime fecha;
  final DateTime? vencimiento;
  final int? clienteId;
  final String? clienteNombre;
  final double subtotal;
  final double itbis;
  final double descuento;
  final double montoDescuento;
  final double montoTotal;
  final int? descuentoId;
  final String? descuentoNombre;
  CotizacionState copyWith({
    String? numero,
    DateTime? fecha,
    DateTime? vencimiento,
    int? clienteId,
    String? clienteNombre,
    double? subtotal,
    double? itbis,
    double? descuento,
    double? montoDescuento,
    double? montoTotal,
    int? descuentoId,
    String? descuentoNombre,
  }) {
    return CotizacionState(
      numero: numero ?? this.numero,
      fecha: fecha ?? this.fecha,
      vencimiento: vencimiento ?? this.vencimiento,
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      subtotal: subtotal ?? this.subtotal,
      itbis: itbis ?? this.itbis,
      descuento: descuento ?? this.descuento,
      montoDescuento: montoDescuento ?? this.montoDescuento,
      montoTotal: montoTotal ?? this.montoTotal,
      descuentoId: descuentoId ?? this.descuentoId,
      descuentoNombre: descuentoNombre ?? this.descuentoNombre,
    );
  }
}
class CotizacionNotifier extends StateNotifier<CotizacionState> {
  CotizacionNotifier()
      : super(CotizacionState(
          numero: '',
          fecha: DateTime.now(),
          subtotal: 0.0,
          itbis: 0.0,
          descuento: 0.0,
          montoDescuento: 0.0,
          montoTotal: 0.0,
        ));
  void seleccionarCliente(int id, String nombre) {
    state = state.copyWith(
      clienteId: id,
      clienteNombre: nombre,
    );
  }
  void establecerVencimiento(DateTime fecha) {
    state = state.copyWith(vencimiento: fecha);
  }
  bool validarAntesDeGuardar() {
    if (state.clienteId == null || state.clienteNombre == null || state.clienteNombre!.trim().isEmpty) {
      return false;
    }
    if (state.numero.trim().isEmpty) {
      return false;
    }
    if (state.montoTotal <= 0) {
      return false;
    }
    return true;
  }
  void vaciar() {
    state = CotizacionState(
      numero: '',
      fecha: DateTime.now(),
      subtotal: 0.0,
      itbis: 0.0,
      descuento: 0.0,
      montoDescuento: 0.0,
      montoTotal: 0.0,
    );
  }
  void aplicarDescuento(double valor) {
    final nuevoSubtotal = state.subtotal;
    final nuevoDescuento = valor;
    final baseImponible = nuevoSubtotal - nuevoDescuento;
    const tasaItbis = 0.18;
    final nuevoItbis = baseImponible * tasaItbis;
    final nuevoTotal = baseImponible + nuevoItbis;
    state = state.copyWith(
      descuento: nuevoDescuento,
      montoDescuento: nuevoDescuento,
      itbis: nuevoItbis,
      montoTotal: nuevoTotal,
    );
  }
  void quitarDescuento() {
    final baseImponible = state.subtotal;
    const tasaItbis = 0.18;
    final nuevoItbis = baseImponible * tasaItbis;
    final nuevoTotal = baseImponible + nuevoItbis;
    state = state.copyWith(
      descuento: 0.0,
      montoDescuento: 0.0,
      itbis: nuevoItbis,
      montoTotal: nuevoTotal,
      descuentoId: null,
      descuentoNombre: null,
    );
  }
}
final cotizacionProvider =
    StateNotifierProvider<CotizacionNotifier, CotizacionState>((ref) {
  return CotizacionNotifier();
});
