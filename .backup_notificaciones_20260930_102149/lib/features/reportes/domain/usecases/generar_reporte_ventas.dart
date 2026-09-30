import 'package:fiscogest_rd/features/reportes/domain/repositories/i_reportes_repository.dart';

class GenerarReporteVentas {
  GenerarReporteVentas(this._repository);
  final IReportesRepository _repository;

  Future<Map<String, dynamic>?> call({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    return await _repository.obtenerDatos('ventas', fechaInicio, fechaFin);
  }
}
