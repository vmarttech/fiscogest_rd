import 'package:flutter/foundation.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/sync/supabase/negocio_local.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';

class FioSync {
  FioSync(this._db);
  final AppDatabase _db;

  Future<void> pushTodos() async {
    if (!SupabaseConfig.isConfigured) return;
    final negocioId = await NegocioLocal.getId();
    if (negocioId == null || negocioId.isEmpty) {
      debugPrint('FioSync: sin negocio_id');
      return;
    }
    final rows = await _db.select(_db.fiosTable).get();
    if (rows.isEmpty) {
      debugPrint('FioSync: no hay fios locales');
      return;
    }
    final payload = rows
        .map((f) => <String, dynamic>{
              'negocio_id': negocioId,
              'id_local': f.id,
              'nombre_cliente': f.nombreCliente,
              'monto_original': f.montoOriginal,
              'monto_abonado': f.montoAbonado,
              'saldo_pendiente': f.saldoPendiente,
              'fecha': f.fecha.toUtc().toIso8601String(),
              'nota': f.nota,
              'estado': f.estado,
              'venta_id_local': f.ventaId,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
        .toList();
    await SupabaseRestClient().upsert(
      table: 'fios',
      rows: payload,
      onConflict: 'negocio_id,id_local',
    );
    debugPrint('FioSync: OK → ${payload.length}');
  }
}
