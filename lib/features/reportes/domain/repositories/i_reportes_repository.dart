/// Contrato abstracto para el repositorio de Reportes.
///
/// Define operaciones de actualización y consulta de datos
/// para reportes comerciales, sin exponer detalles de almacenamiento.
abstract class IReportesRepository {
  /// Actualiza los datos del reporte tras una operación comercial.
  Future<void> actualizarDatos({
    required String tipoOperacion,
    required DateTime fecha,
    required Map<String, dynamic> datos,
  });

  /// Obtiene los datos del reporte según tipo y rango de fechas.
  Future<Map<String, dynamic>?> obtenerDatos(String tipoReporte, DateTime desde, DateTime hasta);
}
