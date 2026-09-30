import 'package:fiscogest_rd/features/estadisticas/domain/repositories/i_estadisticas_repository.dart';

class ActualizarEstadisticas {
  ActualizarEstadisticas(this._repositorio);
  final IEstadisticasRepository _repositorio;

  Future<void> call({
    required String tipoOperacion,
    required double monto,
    required DateTime fecha,
  }) async {
    await _repositorio.incrementarContador(tipoOperacion, monto, fecha);
  }
}
