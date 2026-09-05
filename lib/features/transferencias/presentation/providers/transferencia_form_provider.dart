import 'package:riverpod/riverpod.dart';

class TransferenciaFormState {

  const TransferenciaFormState({
    this.almacenOrigen,
    this.almacenDestino,
    this.cantidad,
  });
  final String? almacenOrigen;
  final String? almacenDestino;
  final String? cantidad;

  bool get esValido =>
      almacenOrigen != null && almacenDestino != null && cantidad != null && almacenOrigen != almacenDestino;

  TransferenciaFormState copiar({
    String? almacenOrigen,
    String? almacenDestino,
    String? cantidad,
  }) {
    return TransferenciaFormState(
      almacenOrigen: almacenOrigen ?? this.almacenOrigen,
      almacenDestino: almacenDestino ?? this.almacenDestino,
      cantidad: cantidad ?? this.cantidad,
    );
  }
}

class TransferenciaFormNotifier extends Notifier<TransferenciaFormState> {
  @override
  TransferenciaFormState build() {
    return const TransferenciaFormState();
  }

  void seleccionarAlmacenOrigen(String valor) {
    state = state.copiar(almacenOrigen: valor);
  }

  void seleccionarAlmacenDestino(String valor) {
    state = state.copiar(almacenDestino: valor);
  }

  void asignarCantidad(String valor) {
    state = state.copiar(cantidad: valor);
  }

  Future<void> enviar() async {
    if (!state.esValido) return;
  }
}

final transferenciaFormProvider =
    NotifierProvider<TransferenciaFormNotifier, TransferenciaFormState>(
  TransferenciaFormNotifier.new,
);
