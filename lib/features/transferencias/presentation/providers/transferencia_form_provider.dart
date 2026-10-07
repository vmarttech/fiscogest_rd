import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/transferencias/data/services/transferencia_service.dart';
import 'package:fiscogest_rd/features/transferencias/domain/entities/transferencia.dart';

final transferenciaServiceProvider = Provider<TransferenciaService>((ref) {
  return TransferenciaService(ref.watch(databaseProvider));
});

class TransferenciaFormState {
  const TransferenciaFormState({
    this.almacenOrigen,
    this.almacenDestino,
    this.productoId,
    this.cantidad,
    this.nota,
    this.enviando = false,
    this.error,
  });

  final String? almacenOrigen; // id as string (compat UI)
  final String? almacenDestino;
  final int? productoId;
  final String? cantidad;
  final String? nota;
  final bool enviando;
  final String? error;

  bool get esValido {
    final c = double.tryParse((cantidad ?? '').replaceAll(',', '.'));
    return almacenOrigen != null &&
        almacenDestino != null &&
        almacenOrigen != almacenDestino &&
        productoId != null &&
        c != null &&
        c > 0 &&
        !enviando;
  }

  TransferenciaFormState copiar({
    String? almacenOrigen,
    String? almacenDestino,
    int? productoId,
    String? cantidad,
    String? nota,
    bool? enviando,
    String? error,
    bool clearError = false,
  }) {
    return TransferenciaFormState(
      almacenOrigen: almacenOrigen ?? this.almacenOrigen,
      almacenDestino: almacenDestino ?? this.almacenDestino,
      productoId: productoId ?? this.productoId,
      cantidad: cantidad ?? this.cantidad,
      nota: nota ?? this.nota,
      enviando: enviando ?? this.enviando,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TransferenciaFormNotifier extends Notifier<TransferenciaFormState> {
  @override
  TransferenciaFormState build() => const TransferenciaFormState();

  void seleccionarAlmacenOrigen(String valor) {
    state = state.copiar(almacenOrigen: valor, clearError: true);
  }

  void seleccionarAlmacenDestino(String valor) {
    state = state.copiar(almacenDestino: valor, clearError: true);
  }

  void seleccionarProducto(int id) {
    state = state.copiar(productoId: id, clearError: true);
  }

  void asignarCantidad(String valor) {
    state = state.copiar(cantidad: valor, clearError: true);
  }

  void asignarNota(String valor) {
    state = state.copiar(nota: valor);
  }

  Future<bool> enviar() async {
    if (!state.esValido) return false;
    state = state.copiar(enviando: true, clearError: true);
    try {
      final svc = ref.read(transferenciaServiceProvider);
      await svc.registrar(
        origenId: int.parse(state.almacenOrigen!),
        destinoId: int.parse(state.almacenDestino!),
        productoId: state.productoId!,
        cantidad: double.parse(state.cantidad!.replaceAll(',', '.')),
        nota: (state.nota ?? '').trim().isEmpty ? null : state.nota!.trim(),
      );
      state = const TransferenciaFormState();
      ref.invalidate(transferenciasHistorialProvider);
      return true;
    } catch (e) {
      state = state.copiar(enviando: false, error: e.toString());
      return false;
    }
  }
}

final transferenciaFormProvider =
    NotifierProvider<TransferenciaFormNotifier, TransferenciaFormState>(
      TransferenciaFormNotifier.new,
    );

final transferenciasHistorialProvider =
    FutureProvider<List<Transferencia>>((ref) async {
  final svc = ref.watch(transferenciaServiceProvider);
  return svc.historial();
});

final stockOrigenProvider = FutureProvider<double>((ref) async {
  final form = ref.watch(transferenciaFormProvider);
  if (form.productoId == null || form.almacenOrigen == null) return 0;
  final svc = ref.watch(transferenciaServiceProvider);
  return svc.stockEn(form.productoId!, int.parse(form.almacenOrigen!));
});
