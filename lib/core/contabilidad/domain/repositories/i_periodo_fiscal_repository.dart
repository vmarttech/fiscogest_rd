import 'package:fiscogest_rd/core/contabilidad/domain/entities/periodo_fiscal.dart';

abstract class IPeriodoFiscalRepository {
  Future<PeriodoFiscal?> periodoAbiertoQueContiene(DateTime fecha, {String? paisCodigo});
  Future<List<PeriodoFiscal>> listar({String? paisCodigo});
  Future<int> insertar(PeriodoFiscal periodo);
  Future<bool> cerrar(int periodoId);
  /// Crea el periodo del año civil actual si no hay ninguno (idempotente por país).
  Future<void> asegurarPeriodoAnualActual(String paisCodigo);
}
