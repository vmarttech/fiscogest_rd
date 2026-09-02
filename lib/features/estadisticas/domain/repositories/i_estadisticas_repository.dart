/// Contrato abstracto para el repositorio de Estadísticas.
///
/// Define operaciones de actualización y consulta de contadores
/// y métricas comerciales, sin exponer detalles de almacenamiento.
abstract class IEstadisticasRepository {
  /// Incrementa un contador por tipo de operación con su monto asociado.
  Future<void> incrementarContador(
    String tipoOperacion,
    double monto,
    DateTime fecha,
  );

  /// Obtiene el total acumulado por tipo de operación en un rango de fechas.
  Future<double?> obtenerTotal(
    String tipoOperacion,
    DateTime desde,
    DateTime hasta,
  );
}
