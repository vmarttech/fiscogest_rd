import 'package:fiscogest_rd/features/estadisticas/domain/repositories/i_estadisticas_repository.dart';

class EstadisticasRepositoryImpl implements IEstadisticasRepository {
  final _contadores = <String, List<Map<String, dynamic>>>{};

  @override
  Future<void> incrementarContador(
    String tipoOperacion,
    double monto,
    DateTime fecha,
  ) async {
    _contadores.putIfAbsent(tipoOperacion, () => []).add({
      'monto': monto,
      'fecha': fecha.toIso8601String(),
    });
  }

  @override
  Future<double?> obtenerTotal(
    String tipoOperacion,
    DateTime desde,
    DateTime hasta,
  ) async {
    final registros = _contadores[tipoOperacion] ?? [];
    return registros.fold<double>(
      0.0,
      (sum, r) => sum + (r['monto'] as double),
    );
  }
}
