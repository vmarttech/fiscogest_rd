import 'package:fiscogest_rd/core/database/app_database.dart';

/// Plan local como puerta de sincronización. La licencia remota se actualiza
/// primero mediante [LicenciaSync.pullDesdeNegocio].
class LicenciaSyncPolicy {
  static Future<bool> puedeSincronizarDatosOperativos(AppDatabase db) async {
    final rows = await db.select(db.licenciasTable).get();
    if (rows.isEmpty) return false;
    rows.sort((a, b) => b.id.compareTo(a.id));
    final preferidas = rows.where(
      (row) => row.plan == 'desarrollador' || row.vitalicia,
    );
    final licencia = preferidas.isNotEmpty ? preferidas.first : rows.first;
    if (licencia.plan.toLowerCase() == 'gratis') return false;
    return licencia.estado == 'activa' ||
        licencia.estado == 'gracia' ||
        licencia.plan == 'desarrollador' ||
        licencia.vitalicia;
  }
}
