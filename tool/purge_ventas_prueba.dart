import 'package:fiscogest_rd/core/database/app_database.dart';

/// Purga ventas de prueba y datos ligados.
/// Cierra la app antes. Uso:
///   dart run tool/purge_ventas_prueba.dart
Future<void> main() async {
  final db = AppDatabase();
  try {
    await db.transaction(() async {
      // Hijos primero (ventas_detalle tiene ON DELETE CASCADE, pero por si acaso)
      await db.customStatement('DELETE FROM ventas_detalle_table');
      await db.customStatement('DELETE FROM caja_movimientos_table');
      try {
        await db.customStatement('DELETE FROM caja_sesiones_table');
      } catch (_) {
        try {
          await db.customStatement('DELETE FROM sesiones_caja_table');
        } catch (_) {}
      }
      // Kardex comercial / inventario ligado a pruebas
      try {
        await db.customStatement('DELETE FROM kardex_comercial_table');
      } catch (_) {}
      try {
        await db.customStatement('DELETE FROM kardex_table');
      } catch (_) {}
      // CxC
      for (final t in [
        'cuotas_cobrar_table',
        'cuentas_cobrar_table',
        'cuentas_por_cobrar_table',
      ]) {
        try {
          await db.customStatement('DELETE FROM $t');
        } catch (_) {}
      }
      // Ventas / cotizaciones
      await db.customStatement('DELETE FROM ventas_table');
    });
    print('OK: historial de ventas de prueba eliminado.');
    print('Usuarios, productos, config y NCF NO se tocaron.');
  } catch (e, st) {
    print('ERROR: $e\n$st');
  } finally {
    await db.close();
  }
}
