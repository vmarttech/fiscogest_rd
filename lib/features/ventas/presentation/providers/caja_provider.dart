import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FormaPago { efectivo, tarjeta, transferencia, credito }

extension FormaPagoNombre on FormaPago {
  String get nombre => switch (this) {
    FormaPago.efectivo => 'Efectivo',
    FormaPago.tarjeta => 'Tarjeta',
    FormaPago.transferencia => 'Transferencia',
    FormaPago.credito => 'Crédito',
  };
}

@immutable
class CajaState {
  const CajaState({
    required this.montoTotal,
    this.esCredito = false,
    this.abono = 0.0,
    this.formasDePago = const [],
    this.referencia = '',
  });

  final double montoTotal;
  final bool esCredito;
  final double abono;
  final List<(FormaPago, double)> formasDePago;
  final String referencia;

  double get totalPagado => formasDePago.fold(0.0, (sum, p) => sum + p.$2);
  double get saldoPendiente => montoTotal - totalPagado;
  bool get pagoCompleto => !esCredito && totalPagado >= montoTotal;
  bool get abonoValido => esCredito && abono > 0 && abono <= montoTotal;

  CajaState copyWith({
    double? montoTotal,
    bool? esCredito,
    double? abono,
    List<(FormaPago, double)>? formasDePago,
    String? referencia,
  }) {
    return CajaState(
      montoTotal: montoTotal ?? this.montoTotal,
      esCredito: esCredito ?? this.esCredito,
      abono: abono ?? this.abono,
      formasDePago: formasDePago ?? this.formasDePago,
      referencia: referencia ?? this.referencia,
    );
  }
}

class CajaNotifier extends StateNotifier<CajaState> {
  CajaNotifier() : super(const CajaState(montoTotal: 0.0));

  void inicializarVenta(double montoTotal, bool esCredito) {
    state = CajaState(montoTotal: montoTotal, esCredito: esCredito);
  }

  void establecerAbono(double valor) {
    state = state.copyWith(
      abono: valor,
      formasDePago: [(FormaPago.efectivo, valor)],
    );
  }

  void agregarPago(FormaPago forma, double monto, String referencia) {
    final actuales = List<(FormaPago, double)>.from(state.formasDePago);
    actuales.add((forma, monto));
    state = state.copyWith(formasDePago: actuales, referencia: referencia);
  }

  void quitarPago(int indice) {
    final actuales = List<(FormaPago, double)>.from(state.formasDePago);
    if (indice >= 0 && indice < actuales.length) {
      actuales.removeAt(indice);
      state = state.copyWith(formasDePago: actuales);
    }
  }

  void limpiar() {
    state = const CajaState(montoTotal: 0.0);
  }

  bool validarCobroCompleto() {
    if (state.esCredito) return state.abonoValido;
    return state.pagoCompleto;
  }
}

final cajaProvider = StateNotifierProvider<CajaNotifier, CajaState>((ref) {
  return CajaNotifier();
});
