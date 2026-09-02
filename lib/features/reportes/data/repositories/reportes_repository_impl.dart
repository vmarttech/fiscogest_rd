import 'package:fiscogest_rd/features/reportes/domain/repositories/i_reportes_repository.dart';

class ReportesRepositoryImpl implements IReportesRepository {
  final _datos = <String, List<Map<String, dynamic>>>{};

  @override
  Future<void> actualizarDatos({
    required String tipoOperacion,
    required DateTime fecha,
    required Map<String, dynamic> datos,
  }) async {
    _datos.putIfAbsent(tipoOperacion, () => []).add({
      ...datos,
      'fecha': fecha.toIso8601String(),
    });
  }

  @override
  Future<Map<String, dynamic>?> obtenerDatos(
    String tipoReporte,
    DateTime desde,
    DateTime hasta,
  ) async {
    final registros = _datos[tipoReporte] ?? [];
    return {'total': registros.length, 'registros': registros};
  }
}
