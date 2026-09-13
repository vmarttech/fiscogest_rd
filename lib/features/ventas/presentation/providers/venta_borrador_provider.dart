import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';

@immutable
class VentaBorradorState {
  const VentaBorradorState({
    this.id,
    required this.numero,
    required this.fecha,
    this.vencimiento,
    this.clienteId,
    this.clienteNombre,
    required this.subtotal,
    required this.itbis,
    this.costoEnvio = 0.0,
    this.descuento,
    this.descuentoId,
    this.descuentoNombre,
    required this.montoDescuento,
    required this.montoTotal,
    this.tipoPago = 'Contado',
    this.esCredito = false,
    this.detalles = const [],
    this.estadoDocumento = EstadoDocumento.borrador,
  });

  final int? id;
  final String numero;
  final DateTime fecha;
  final DateTime? vencimiento;
  final int? clienteId;
  final String? clienteNombre;
  final double subtotal;
  final double itbis;
  final double costoEnvio;
  final double? descuento;
  final int? descuentoId;
  final String? descuentoNombre;
  final double montoDescuento;
  final double montoTotal;
  final String tipoPago;
  final bool esCredito;
  final List<dynamic> detalles;
  final EstadoDocumento estadoDocumento;

  VentaBorradorState copyWith({
    int? id,
    String? numero,
    DateTime? fecha,
    DateTime? vencimiento,
    int? clienteId,
    String? clienteNombre,
    double? subtotal,
    double? itbis,
    double? costoEnvio,
    double? descuento,
    int? descuentoId,
    String? descuentoNombre,
    double? montoDescuento,
    double? montoTotal,
    String? tipoPago,
    bool? esCredito,
    List<dynamic>? detalles,
    EstadoDocumento? estadoDocumento,
  }) {
    return VentaBorradorState(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      fecha: fecha ?? this.fecha,
      vencimiento: vencimiento ?? this.vencimiento,
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      subtotal: subtotal ?? this.subtotal,
      itbis: itbis ?? this.itbis,
      costoEnvio: costoEnvio ?? this.costoEnvio,
      descuento: descuento ?? this.descuento,
      descuentoId: descuentoId ?? this.descuentoId,
      descuentoNombre: descuentoNombre ?? this.descuentoNombre,
      montoDescuento: montoDescuento ?? this.montoDescuento,
      montoTotal: montoTotal ?? this.montoTotal,
      tipoPago: tipoPago ?? this.tipoPago,
      esCredito: esCredito ?? this.esCredito,
      detalles: detalles ?? this.detalles,
      estadoDocumento: estadoDocumento ?? this.estadoDocumento,
    );
  }
}

class VentaBorradorNotifier extends StateNotifier<VentaBorradorState> {
  VentaBorradorNotifier()
    : super(
        VentaBorradorState(
          numero: '',
          fecha: DateTime.now(),
          subtotal: 0.0,
          itbis: 0.0,
          costoEnvio: 0.0,
          descuento: 0.0,
          montoDescuento: 0.0,
          montoTotal: 0.0,
        ),
      );

  void seleccionarCliente(int id, String nombre) {
    state = state.copyWith(clienteId: id, clienteNombre: nombre);
  }

  void establecerConsumidorFinal() {
    state = state.copyWith(clienteId: 0, clienteNombre: 'Consumidor Final');
  }

  void establecerVencimiento(DateTime fecha) {
    state = state.copyWith(vencimiento: fecha);
  }

  void establecerNumeroCotizacion(String numero) {
    state = state.copyWith(numero: numero);
  }

  void establecerEstadoDocumento(EstadoDocumento estado) {
    state = state.copyWith(estadoDocumento: estado);
  }

  void _recalcularTotal({
    double? nuevoSubtotal,
    double? nuevoItbis,
    double? nuevoEnvio,
    double? nuevoDescuento,
  }) {
    final subt = nuevoSubtotal ?? state.subtotal;
    final itb = nuevoItbis ?? state.itbis;
    final env = nuevoEnvio ?? state.costoEnvio;
    final desc = nuevoDescuento ?? state.montoDescuento;
    final total = subt + itb + env - desc;
    state = state.copyWith(
      subtotal: subt,
      itbis: itb,
      costoEnvio: env,
      montoDescuento: desc,
      montoTotal: total,
    );
  }

  void asignarCostoEnvio(double valor) {
    _recalcularTotal(nuevoEnvio: valor);
  }

  void aplicarDescuento(double valor) {
    final baseImponible = state.subtotal - valor;
    const tasaItbis = 0.18;
    final nuevoItbis = baseImponible * tasaItbis;
    final subtMasItbis = baseImponible + nuevoItbis;
    final nuevoTotal = subtMasItbis + state.costoEnvio;
    state = state.copyWith(
      descuento: valor,
      montoDescuento: valor,
      itbis: nuevoItbis,
      montoTotal: nuevoTotal,
    );
  }

  void quitarDescuento() {
    final baseImponible = state.subtotal;
    const tasaItbis = 0.18;
    final nuevoItbis = baseImponible * tasaItbis;
    final subtMasItbis = baseImponible + nuevoItbis;
    final nuevoTotal = subtMasItbis + state.costoEnvio;
    state = state.copyWith(
      descuento: 0.0,
      descuentoId: null,
      descuentoNombre: null,
      montoDescuento: 0.0,
      itbis: nuevoItbis,
      montoTotal: nuevoTotal,
    );
  }

  void vaciar() {
    state = VentaBorradorState(
      numero: '',
      fecha: DateTime.now(),
      subtotal: 0.0,
      itbis: 0.0,
      costoEnvio: 0.0,
      descuento: 0.0,
      montoDescuento: 0.0,
      montoTotal: 0.0,
      tipoPago: 'Contado',
      esCredito: false,
      detalles: const [],
      estadoDocumento: EstadoDocumento.borrador,
    );
  }

  bool validarAntesDeGuardar() {
    final bool tieneCliente = state.clienteId != null &&
        state.clienteId! > 0 &&
        (state.clienteNombre?.trim().isNotEmpty ?? false);
    final bool esConsumidorFinal = state.clienteId == 0 &&
        state.clienteNombre == 'Consumidor Final';
    if (!tieneCliente && !esConsumidorFinal) return false;
    if (state.numero.trim().isEmpty) return false;
    if (state.montoTotal <= 0) return false;
    return true;
  }

  String? guardar() {
    if (!validarAntesDeGuardar()) return null;
    return state.numero.trim().isNotEmpty ? state.numero : null;
  }
}

final ventaBorradorProvider =
    StateNotifierProvider<VentaBorradorNotifier, VentaBorradorState>((ref) {
  return VentaBorradorNotifier();
});
