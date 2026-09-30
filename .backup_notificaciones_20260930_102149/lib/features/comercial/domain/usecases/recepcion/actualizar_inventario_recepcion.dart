import 'package:fiscogest_rd/features/comercial/domain/entities/recepcion.dart';

/// Entrada de inventario al CONFIRMAR compra ([ConfirmarCompraServices]).
/// Recepción no vuelve a sumar stock (evita duplicar cantidad/costo).
class ActualizarInventarioRecepcion {
  ActualizarInventarioRecepcion([Object? _]);

  Future<void> ejecutar(final Recepcion recepcion) async {
    // No-op a propósito.
  }
}
