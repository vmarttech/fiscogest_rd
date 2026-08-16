import 'package:fiscogest_rd/features/caja/domain/repositories/i_caja_repository.dart';

class ActualizarCaja {
  ActualizarCaja(this._repositorio);
  final ICajaRepository _repositorio;

  Future<void> call({
    required String referencia,
    required double monto,
    required String tipo,
    required String descripcion,
  }) async {
    await _repositorio.registrarMovimiento(
      referencia: referencia,
      monto: monto,
      tipo: tipo,
      descripcion: descripcion,
    );
  }
}
