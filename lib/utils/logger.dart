import 'package:logger/logger.dart';

/// 📌 Servicio centralizado de registros
/// Reemplaza todos los print() del proyecto, permite controlar qué se ve
/// en consola y en el futuro se puede guardar en archivos o enviarlo a servicios externos
class AppLogger {
  // Instancia única configurada
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      // ✅ Cambiamos la opción obsoleta por la nueva
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  // Niveles de registro según gravedad
  static void debug(String mensaje, [dynamic dato]) {
    _logger.d(_formatear(mensaje, dato));
  }

  static void info(String mensaje, [dynamic dato]) {
    _logger.i(_formatear(mensaje, dato));
  }

  static void advertencia(String mensaje, [dynamic dato]) {
    _logger.w(_formatear(mensaje, dato));
  }

  static void error(String mensaje, [dynamic error, StackTrace? traza]) {
    _logger.e(_formatear(mensaje, error), error: error, stackTrace: traza);
  }

  // Método auxiliar para unir mensaje y datos adicionales
  static String _formatear(String mensaje, [dynamic dato]) {
    if (dato == null) return mensaje;
    return '$mensaje | Detalle: $dato';
  }
}