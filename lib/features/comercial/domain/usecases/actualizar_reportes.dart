import 'package:fiscogest_rd/features/reportes/domain/repositories/i_reportes_repository.dart';

class ActualizarReportes {
  ActualizarReportes(this._repositorio);
  final IReportesRepository _repositorio;

  Future<void> call({
    required String tipoOperacion,
    required DateTime fecha,
    required Map<String, dynamic> datos,
  }) async {
    await _repositorio.actualizarDatos(
      tipoOperacion: tipoOperacion,
      fecha: fecha,
      datos: datos,
    );
  }
}
